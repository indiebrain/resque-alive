# frozen_string_literal: true

require "resque"
require "resque/plugins/alive/config"
require "resque/plugins/alive/heartbeat"
require "resque/plugins/alive/server"
require "resque/plugins/alive/version"

module Resque
  module Plugins
    module Alive
      module Redis
        TTL_EXPIRED = -2
      end

      def self.procline(string)
        $0 = "resque-alive-#{Resque::Plugins::Alive::VERSION}: #{string}"
        logger.send(:debug, $0)
      end

      def self.start
        append_resque_alive_heartbeat_queue
        Resque.before_first_fork do
          Resque::Plugins::Alive.tap do |resque_alive|
            procline("starting")
            logger.info(banner)
            register_current_instance
            store_alive_key

            procline("registering heartbeat")
            Resque.enqueue(
              Heartbeat,
              hostname
            )

            procline("initializing webserver")
            @server_pid = fork do
              procline("listening on port: #{config.port} at path: #{config.path}")
              resque_alive::Server.run!
            end

            logger.info(successful_startup_text)

            # TODO: worker_exit is, an as yet unreleased feature of
            # resque. If the version of resque used by the host
            # application doesn't yet support worker_exit, register an
            # Kernel#at_exit hook to gracefully shutdown resque-alive.
            unless Resque.respond_to?(:worker_exit)
              at_exit do
                Resque::Plugins::Alive.shutdown
              end
            end
          end

          # TODO: worker_exit is, an as yet unreleased feature of
          # resque, but should be the preferred method of triggering a
          # graceful shutdown of resque-alive.
          #
          # https://github.com/resque/resque/blob/master/HISTORY.md#unreleased
          if Resque.respond_to?(:worker_exit)
            Resque.worker_exit do
              Resque::Plugins::Alive.shutdown
            end
          end
        end

        Resque.before_pause do
          Resque::Plugins::Alive.unregister_current_instance
        end
      end

      def self.shutdown
        procline("shutting down webserver #{@server_pid}")
        Process.kill('TERM', @server_pid) unless @server_pid.nil?
        Process.wait(@server_pid) unless @server_pid.nil?

        procline("unregistering resque_alive")
        Resque::Plugins::Alive.unregister_current_instance

        procline("shutting down...")
      end

      QUEUE_ENV_VARS = %w(QUEUE QUEUES)
      def self.append_resque_alive_heartbeat_queue
        QUEUE_ENV_VARS.each do |env_var|
          if ENV[env_var]
            ENV[env_var] = [ENV[env_var], current_queue].join(",")
          end
        end
      end

      def self.config
        @config ||= Config.instance
      end

      def self.setup
        yield(config)
      end

      def self.redis
        Resque.redis { |r| r }
      end

      def self.current_liveness_key
        "#{config.liveness_key}::#{hostname}"
      end

      def self.hostname
        config.hostname
      end

      def self.store_alive_key
        redis.set(
          current_liveness_key,
          Time.now.to_i,
          ex: config.time_to_live.to_i
        )
      end

      def self.alive?
        redis.ttl(current_liveness_key) != Redis::TTL_EXPIRED
      end

      def self.registered_instances
        redis.keys("#{config.registered_instance_key}::*")
      end

      def self.register_current_instance
        register_instance(current_instance_register_key)
      end

      def self.current_instance_register_key
        "#{config.registered_instance_key}::#{hostname}"
      end


      def self.register_instance(instance_name)
        redis.set(
          instance_name,
          Time.now.to_i,
          ex: config.registration_ttl.to_i
        )
      end

      def self.unregister_current_instance
        # Delete any pending jobs for this instance
        logger.info(shutdown_info)
        purge_pending_jobs
        redis.del(current_instance_register_key)
      end

      def self.purge_pending_jobs
        logger.info("[Resque::Plugins::Alive] Begin purging pending jobs for queue #{current_queue}")
        pending_heartbeat_jobs_count = Resque::Job.destroy(current_queue, Heartbeat)
        logger.info("[Resque::Plugins::Alive] Purged #{pending_heartbeat_jobs_count} pending for #{hostname}")
        logger.info("[Resque::Plugins::Alive] Removing queue #{current_queue}")
        Resque.remove_queue(current_queue)
        logger.info("[Resque::Plugins::Alive] Finished purging pending jobs for queue #{current_queue}")
      end

      def self.logger
        Resque.logger
      end

      def self.banner
        <<~BANNER
          =================== Resque::Plugins::Alive =================
          Hostname: #{hostname}
          Liveness key: #{current_liveness_key}
          Port: #{config.port}
          Time to live: #{config.time_to_live}s
          Current instance register key: #{current_instance_register_key}
          Worker running on queue: #{@queue}
          starting ...
        BANNER
      end

      def self.shutdown_info
        <<~BANNER
          =================== Shutting down Resque::Plugins::Alive =================
          Hostname: #{hostname}
          Liveness key: #{current_liveness_key}
          Current instance register key: #{current_instance_register_key}
        BANNER
      end

      def self.current_queue
        Heartbeat.current_queue
      end

      def self.successful_startup_text
        <<~BANNER
          Registered instances:
          - #{registered_instances.join("\n\s\s- ")}
          =================== Resque::Plugins::Alive Ready! =================
        BANNER
      end

      def self.enabled?
        config.enabled
      end
    end
  end
end

Resque::Plugins::Alive.start if Resque::Plugins::Alive.enabled?
