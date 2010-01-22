namespace :rageios do
    task :reaper => :setup do
        require 'resque'
        require 'rageios'

        worker = nil
        queues = ["reaper"]

        worker = Resque::Worker.new(*queues)
        worker.very_verbose = ENV['DEBUG']

        puts "*** Starting reaper #{worker}"

        worker.work(1)
    end

    task :checker, :queue do |t, args|
        require 'resque'

        worker = nil
        queues = [args.queue]

        worker = Resque::Worker.new(*queues)
        worker.very_verbose = ENV['DEBUG']

        puts "*** Starting checker #{worker}"

        worker.work(1)
    end
end

begin
    require 'jeweler'
    Jeweler::Tasks.new do |gemspec|
        gemspec.name = "rageios"
        gemspec.summary = "Resque + Nagios == Win?"
        gemspec.description = "Meh"
        gemspec.email = "tim.sharpe@anchor.com.au"
        gemspec.homepage = "http://github.com/rodjek/rageios"
        gemspec.authors = ["Tim Sharpe"]
    end
rescue LoadError
    puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

