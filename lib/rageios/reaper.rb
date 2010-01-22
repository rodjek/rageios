require 'rubygems'
require 'resque'
require 'open3'

module Ragios
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
