module Rageios
  module Check
    include Rageios

    # Usage
    #
    # r = Ragios::Check::Exec.new
    # r.queue = :check
    # r.run "/usr/lib/nagios/plugins/check_http -H localhost"
    class Rageios::Check::Exec
      attr_accessor :queue, :redis_host, :redis_port

      def run(cmd)
        # Have to call Resque::Job directly so that we can dynamically
        # set the queue name rather than hardcoding it into the class
        # definition
        uuid = UUID.new.generate :compact
        Resque::Job.create(@queue, Rageios::Check::Exec, uuid, @redis_host, @redis_port, cmd)

        # Give us an initial 0.1 second wait for the remote end to process the check
        sleep 0.1

        # Wait for the results to appear in Redis
        namespace = "rageios:result:#{uuid}"
        redis = Redis.new :host => @redis_host, :port => @redis_port
        status = redis.get "#{namespace}:status"
        while status.nil?
          sleep 0.1
          status = redis.get "#{namespace}:status"
        end
        output = redis.get "#{namespace}:output"
        
        # Clear the results from Redis
        redis.del "#{namespace}:output" 
        redis.del "#{namespace}:status" 
        
        {:status => status.to_i, :output => output}
      end

      def self.perform(uuid, redis_host, redis_port, command)
        output = ""
        status = POpen4::popen4(command) do |stdout, stderr, stdin, pid|
          stdin.close
          output = stdout.read.strip
        end

        namespace = "rageios:result:#{uuid}"
        redis = Redis.new :host => redis_host, :port => redis_port
        redis.set "#{namespace}:output", output 
        redis.set "#{namespace}:status", status.exitstatus 
      end
    end
  end
end
