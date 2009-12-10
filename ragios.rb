# Yes, I know having this in 1 giant file is all sorts of not nice.  I'm not
# that far through the book yet, mixins & modules are still a couple of
# chapters away

require 'rubygems'
require 'resque'
require 'open3'

module Ragios
    module Check
        include Ragios

        class Ragios::Check::Exec
            def queue
                :check
            end

            def self.perform(host, service, executable, *args)
                args_string = args.join(' ')
                stdin, stdout, stderr = Open3.popen3("#{executable} #{args_string}")

                Resque.enqueue(Ragios::Reaper::ServiceCheck, host, service, $?, stdout.read())
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
                    fd.puts "[#{timestamp}] PROCESS_HOST_CHECK_RESULT;#{host};#{status};#{foo}"
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
