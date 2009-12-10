# Yes, I know having this in 1 giant file is all sorts of not nice.  I'm not
# that far through the book yet, mixins & modules are still a couple of
# chapters away

require 'rubygems'
require 'resque'
require 'open3'

@str_status = {
    0 => "OK",
    1 => "WARNING",
    2 => "CRITICAL",
    3 => "UNKNOWN"
}

module Ragios
    module Check
        include Ragios

        class Ragios::Check::Exec
            @queue = :check

            def self.perform(host, service, executable, *args)
                args_string = args.join(' ')
                stdin, stdout, stderr = Open3.popen3("#{executable} #{args_string}")

                Resque.enqueue(Ragios::Reaper::ServiceCheck, host, service, $?, stdout.read())
            end
        end

        class Ragios::Check::Host
            @queue = :check

            def self.perform(host, ip, count)
                stdin, stdout, stderr = Open3.popen3("/bin/ping -c #{count} #{ip}")

                # Say no to regular expressions!
                data = stdout.readlines()
                rta = data[-1].split('=')[1].split('/')[1]
                lost = data[-2].split(',')[2].split('%')[0].strip

                # Yeah, I'll add thresholds later...
                status = 0

                message = "OK - #{ip}: rta #{rta}, lost #{lost}%"
                Resque.enqueue(Ragios::Reaper::HostCheck, host, status, message)
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
