class Pigeon::Queue
  # == Constants ============================================================
  
  # == Exceptions ===========================================================

  class BlockRequired < Exception
  end
  
  class TaskNotQueued < Exception
  end

  # == Extensions ===========================================================

  # == Relationships ========================================================

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  # == Validations ==========================================================

  # == Class Methods ========================================================
  
  def self.filters
    @filters ||= {
      nil => lambda { |task| true }
    }
  end
  
  def self.filter(name, &block)
    filters[name] = block
  end

  # == Instance Methods =====================================================

  def initialize
    @filter_lock = Mutex.new
    @observer_lock = Mutex.new

    @tasks = [ ]
    @claimable_task = { }
    @filters = self.class.filters.dup
    @observers = { }
    @next_task = { }
    @sort_by = :priority.to_proc
    @insert_backlog = [ ]
  end
  
  def sort_by(&block)
    raise BlockRequired unless (block_given?)

    @sort_by = block
    @filter_lock.synchronize do
      @tasks = @tasks.sort_by(&@sort_by)
      
      @next_task = { }
    end
  end
  
  def observe(filter_name = nil, &block)
    raise BlockRequired unless (block_given?)
    
    @observer_lock.synchronize do
      @observers[filter_name] ||= [ ]
    end

    @observers[filter_name] << block
    
    task = assign_next_task(filter_name)
  end
  
  def filter(filter_name, &block)
    raise BlockRequired unless (block_given?)

    @filter_lock.synchronize do
      @filters[filter_name] = block
    end
    
    assign_next_task(filter_name)
  end
  
  def <<(task)
    # If there is an insert operation already in progress, put this task in
    # the backlog for subsequent processing.
    
    if (@observer_lock.locked?)
      @insert_backlog << task
      return task
    end
    
    active_task = task
    
    while (active_task) do
      # Set the claimable task flag for this task since it is not yet in the
      # actual task queue.
      @filter_lock.synchronize do
        @claimable_task[active_task] = true
      end
    
      @observer_lock.synchronize do
        @observers.each do |filter_name, list|
          # Skip if there is a task scheduled in this slot, something that
          # indicates all the observers have previously passed on it.
          next if (@next_task[filter_name])
        
          # Check if this task matches the filter restrictions, and if it
          # does then call the observer chain in order.
          if (@filters[filter_name].call(active_task))
            @observers[filter_name].each do |proc|
              case (proc.arity)
              when 2
                proc.call(self, active_task)
              else
                proc.call(active_task)
              end

              # An observer callback has the opportunity to claim a task,
              # and if it does, the claimable task flag will be false. Loop
              # only while the task is claimable.
              break unless (@claimable_task[active_task])
            end
          end
        end
      end

        # If this task wasn't claimed by an observer then insert it in the
        # main task queue.
      if (@claimable_task.delete(active_task))
        @filter_lock.synchronize do
          task_sort_by = @sort_by.call(active_task)
          insert_index = @tasks.find_index do |queued_task|
            @sort_by.call(queued_task) > task_sort_by
          end

          @tasks.insert(insert_index || -1, active_task)

          # Update the next task slots for all of the unassigned filters and
          # trigger observer callbacks as required.
          @next_task.each do |filter_name, next_task|
            next if (next_task)
            
            if (@filters[filter_name].call(active_task))
              @next_task[filter_name] = active_task
            end
          end
        end
      end
        
      active_task = @insert_backlog.shift
    end

    task
  end
  
  def each
    @filter_lock.synchronize do
      tasks = @tasks.dup
    end
    
    tasks.each do
      yield(task)
    end
  end
  
  def peek(filter_name = nil, &block)
    if (block_given?)
      @filter_lock.synchronize do
        @tasks.find(&block)
      end
    else
      @next_task[filter_name] ||= begin
        @filter_lock.synchronize do
          filter_proc = @filters[filter_name] 
      
          filter_proc and @tasks.find(&filter_proc)
        end
      end
    end
  end
  
  def pull(filter_name = nil, &block)
    unless (block_given?)
      block = @filters[filter_name]
    end
    
    @filter_lock.synchronize do
      tasks = @tasks.select(&block)
      
      @tasks -= tasks
      
      @next_task.each do |filter_name, next_task|
        if (tasks.include?(@next_task[filter_name]))
          @next_task[filter_name] = nil
        end
      end
      
      tasks
    end
  end

  def pop(filter_name = nil, &block)
    popped_task =
      if (block_given?)
        @filter_lock.synchronize do
          @tasks.find(&block)
        end
      else
        peek(filter_name)
      end
    
    if (popped_task)
      claim(popped_task)
    end

    popped_task
  end
  
  def claim(task)
    @filter_lock.synchronize do
      if (@claimable_task[task])
        @claimable_task[task] = false
      elsif (@tasks.delete(task))
        @next_task.each do |filter_name, next_task|
          if (task == next_task)
            @next_task[filter_name] = nil
          end
        end
      else
        raise TaskNotQueued, task
      end
    end
      
    task
  end
  
  def empty?(filter_name = nil, &block)
    if (block_given?)
      @filter_lock.synchronize do
        !@tasks.find(&block)
      end
    else
      !peek(filter_name)
    end
  end
  
  def length(filter_name = nil, &block)
    filter_proc = @filters[filter_name] 
  
    @filter_lock.synchronize do
      filter_proc ? @tasks.count(&filter_proc) : nil
    end
  end
  alias_method :count, :length
  
protected
  def assign_next_task(filter_name)
    filter = @filters[filter_name]

    return unless (filter)
    
    if (task = @next_task[filter_name])
      return task
    end
    
    @filter_lock.synchronize do
      @next_task[filter_name] ||= @tasks.find(&filter)
    end
  end
end
