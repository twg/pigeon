require 'rubygems'
require 'bundler/setup'

require 'minitest'

module Minitest
  # The default Minitest behavior to intercept at_exit and rewrite the exit
  # status code based on test results is okay for the parent process, but
  # causes friction when using fork within tests. Here it's disabled unless
  # the process terminating is the parent.
  def self.autorun
    at_exit {
      next if $! and not ($!.kind_of? SystemExit and $!.success?)

      exit_code = nil

      at_exit {
        if (Process.pid == @@installed_at_exit)
          @@after_run.reverse_each(&:call)
          exit exit_code || false
        end
      }

      exit_code = Minitest.run ARGV
    } unless @@installed_at_exit

    @@installed_at_exit = Process.pid
  end
end

require 'minitest/autorun'

require 'timeout'

$LOAD_PATH.unshift(File.expand_path(File.join(*%w[ .. lib ]), File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'pigeon'
require 'eventmachine'


class Minitest::Test
  def assert_timeout(time, message = nil, &block)
    Timeout::timeout(time, &block)

  rescue Timeout::Error
    flunk(message || 'assert_timeout timed out')
  end
  
  def assert_eventually(time = nil, message = nil, &block)
    start_time = Time.now.to_f

    while (!block.call)
      select(nil, nil, nil, 0.1)
      
      if (time and (Time.now.to_f - start_time > time))
        flunk(message || 'assert_eventually timed out')
      end
    end
  end

  def engine
    exception = nil
    test_thread = nil
    
    engine_thread =
      Thread.new do
        Thread.abort_on_exception = true

        Pigeon::Engine.clear_engines!

        # Create a thread for the engine to run on
        begin
          Pigeon::Engine.launch do |launched|
            @engine = launched
          end

        rescue Object => exception
        end
      end

    test_thread =
      Thread.new do
        # Execute the test code in a separate thread to avoid blocking
        # the EventMachine loop.
        begin
          while (!Pigeon::Engine.default_engine and !@engine)
            # Wait impatiently.
          end

          yield(@engine)
        rescue Object => exception
        ensure
          begin
            if (EventMachine.reactor_running?)
              EventMachine.stop_event_loop
            end
          rescue Object
            STDERR.puts("[#{exception.class}] #{exception}")
            # Shutting down may trigger an exception from time to time
            # if the engine itself has failed.
          end
        end
      end

    test_thread.join

    begin
      Timeout.timeout(1) do
        engine_thread.join
      end
    rescue Timeout::Error
      engine_thread.kill

      fail 'Execution timed out'
    end
    
    if (exception)
      raise exception
    end
  end
end
