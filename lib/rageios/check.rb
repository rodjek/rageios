require 'rubygems'
require 'resque'
require 'open3'

module Ragios
    module Check
        include Ragios

        # Usage
        #
        # r = Ragios::Check::Exec.new
        # r.host = "localhost"
        # r.service = "HTTP"
        # r.queue = :check
        # r.run("/usr/lib/nagios/plugins/check_http", "-H", "localhost")
        #
        class Ragios::Check::Exec
            attr_accessor :host, :service, :queue

            def run(executable, *args)
                # Have to call Resque::Job directly so that we can dynamically
                # set the queue name rather than hardcoding it into the class
                # definition
                
                Resque::Job.create(@queue, Ragios::Check::Exec, @host, @service, executable, args)
            end

            def self.perform(host, service, executable, *args)
                args_string = args.join(' ')
                stdin, stdout, stderr = Open3.popen3("#{executable} #{args_string}")

                Resque.enqueue(Ragios::Reaper::ServiceCheck, host, service, $?, stdout.read())
            end
        end

        # Usage
        # 
        # r = Ragios::Check::Host.new
        # r.host = "localhost"
        # r.ip = "127.0.0.1"
        # r.queue = :check
        # r.run("1,2", "3,4")
        #
        class Ragios::Check::Host
            attr_accessor :host, :ip, :queue

            def run(warn, crit)
                Resque::Job.create(@queue, Ragios::Check::Host, @host, @ip, warn, crit)
            end

            def self.perform(host, ip, count, warn, crit)
                stdin, stdout, stderr = Open3.popen3("/usr/lib/nagios/plugins/check_ping -H #{ip} -p #{count} -w #{warn}% -c #{crit}%")

                Resque.enqueue(Ragios::Reaper::HostCheck, host, $?, stdout.read)
            end
        end
    end
end
