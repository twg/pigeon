# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "pigeon"
  s.version = "0.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["tadman"]
  s.date = "2011-10-12"
  s.description = "Pigeon is a simple way to get started building an EventMachine engine that's intended to run as a background job."
  s.email = "github@tadman.ca"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/launcher.example",
    "lib/pigeon.rb",
    "lib/pigeon/dispatcher.rb",
    "lib/pigeon/engine.rb",
    "lib/pigeon/launcher.rb",
    "lib/pigeon/logger.rb",
    "lib/pigeon/option_accessor.rb",
    "lib/pigeon/pidfile.rb",
    "lib/pigeon/processor.rb",
    "lib/pigeon/queue.rb",
    "lib/pigeon/scheduler.rb",
    "lib/pigeon/sorted_array.rb",
    "lib/pigeon/support.rb",
    "lib/pigeon/task.rb",
    "pigeon.gemspec",
    "test/helper.rb",
    "test/unit/pigeon_backlog_test.rb",
    "test/unit/pigeon_dispatcher_test.rb",
    "test/unit/pigeon_engine_test.rb",
    "test/unit/pigeon_launcher_test.rb",
    "test/unit/pigeon_option_accessor_test.rb",
    "test/unit/pigeon_processor_test.rb",
    "test/unit/pigeon_queue_test.rb",
    "test/unit/pigeon_scheduler_test.rb",
    "test/unit/pigeon_sorted_array_test.rb",
    "test/unit/pigeon_task_test.rb",
    "test/unit/pigeon_test.rb"
  ]
  s.homepage = "http://github.com/twg/pigeon"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Simple daemonized EventMachine engine framework with plug-in support"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<eventmachine>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0"])
  end
end

