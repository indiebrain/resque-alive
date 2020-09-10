# frozen_string_literal: true

require "resque-scheduler"

module Resque
  module Plugins
    module Alive
      class Heartbeat
        # TODO: For the case where multiple workers exist on the same
        # host, maybe this needs to know the PID of the worker process
        # and namespace the queue to that pid?
        def self.perform(_hostname = config.hostname)
          ping
          schedule_next_heartbeat
        end

        def self.ping
          Alive.store_alive_key
          Alive.register_current_instance

          begin
            config.callback.call
          rescue StandardError
            nil
          end
        end

        def self.schedule_next_heartbeat
          Resque.enqueue_in_with_queue(
            current_queue,
            inside_ttl_window,
            self.name,
            current_hostname
          )
        end

        def self.inside_ttl_window
          config.time_to_live / 2
        end

        def self.current_hostname
          config.hostname
        end

        def self.config
          Config.instance
        end

        def self.current_queue
          "#{config.queue_prefix}-#{current_hostname}"
        end

        @queue = current_queue
      end
    end
  end
end
