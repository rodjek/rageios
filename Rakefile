namespace :resque do
  task :setup do
    require 'ragios'
  end

  desc "Start a Resque worker"
  task :work => :setup do
    require 'resque'

    worker = nil
    queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',')

    begin
      worker = Resque::Worker.new(*queues)
      worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      worker.very_verbose = ENV['VVERBOSE']
    rescue Resque::NoQueueError
      abort "set QUEUE env var, e.g. $ QUEUE=critical,high rake resque:work"
    end

    puts "*** Starting worker #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple Resque workers"
  task :workers do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake resque:work"
      end
    end

    threads.each { |thread| thread.join }
  end
end

namespace :ragios do
    task :setup do
        require 'ragios'
    end

    task :reaper => :setup do
        require 'resque'

        worker = nil
        queues = ["reaper"]

        worker = Resque::Worker.new(*queues)
        worker.very_verbose = ENV['DEBUG']

        puts "*** Starting reaper #{worker}"

        worker.work(1)
    end

    task :checker => :setup do
        require 'resque'

        worker = nil
        queues = ["check"]

        worker = Resque::Worker.new(*queues)
        worker.very_verbose = ENV['DEBUG']

        puts "*** Starting checker #{worker}"

        worker.work(1)
    end
end

begin
    require 'jeweler'
    Jeweler::Tasks.new do |gemspec|
        gemspec.name = "ragios"
        gemspec.summary = "Resque + Nagios == Win?"
        gemspec.description = "Meh"
        gemspec.email = "tim.sharpe@anchor.com.au"
        gemspec.homepage = "http://github.com/rodjek/ragios"
        gemspec.authors = ["Tim Sharpe"]
    end
rescue LoadError
    puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

