# Yes, I know having this in 1 giant file is all sorts of not nice.  I'm not
# that far through the book yet, mixins & modules are still a couple of
# chapters away

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
        # r.run("1,2", "3,4")
        #
        class Ragios::Check::Host
            attr_accessor :host, :ip
            @queue = :check

            def run(warn, crit)
                Resque.enqueue(Ragios::Check::Host, @host, @ip, warn, crit)
            end

            def self.perform(host, ip, count, warn, crit)
                stdin, stdout, stderr = Open3.popen3("/usr/lib/nagios/plugins/check_ping -H #{ip} -p #{count} -w #{warn}% -c #{crit}%")

                Resque.enqueue(Ragios::Reaper::HostCheck, host, $?, stdout.read)
            end
        end
    end

    module Reaper
        include Ragios

        class Ragios::Reaper::HostCheck
            @queue = :reaper

            def self.perform(host, status, message)
                timestamp = Time.now.strftime('%s')

                File.open('/tmp/nagios_foo', 'a') { |fd|
                    fd.puts "[#{timestamp}] PROCESS_HOST_CHECK_RESULT;#{host};#{status};#{message}"
                }
            end
        end

        class Ragios::Reaper::ServiceCheck
            @queue = :reaper

            def self.perform(host, service, status, message)
                timestamp = Time.now.strftime('%s')

                File.open('/tmp/nagios_foo', 'a') { |fd|
                    fd.puts "[#{timestamp}] PROCESS_SERVICE_CHECK_RESULT;#{host};#{service};#{status};#{message}"
                }
            end
        end
    end
end
