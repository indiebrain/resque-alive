# frozen_string_literal: true

require "singleton"

module Resque
  module Plugins
    module Alive
      class Config
        include Singleton

        def initialize
          set_defaults
        end

        def set_defaults
          self.port = ENV["RESQUE_ALIVE_PORT"] || 7433
          self.path = ENV["RESQUE_ALIVE_PATH"] || "/"
          self.liveness_key = "RESQUE::LIVENESS_PROBE_TIMESTAMP"
          self.time_to_live = 10 * 60
          self.callback = proc {}
          self.registered_instance_key = "RESQUE_REGISTERED_INSTANCE"
          self.queue_prefix = :resque_alive
          self.server = ENV["RESQUE_ALIVE_SERVER"] || "webrick"
          self.hostname = ENV["HOSTNAME"] || "HOSTNAME_NOT_SET"
          self.enabled = !ENV["RESQUE_ALIVE_DISABLED"]
        end

        def enabled?
          enabled
        end

        def registration_ttl
          @registration_ttl || time_to_live + 60
        end

        attr_accessor(
          :callback,
          :enabled,
          :hostname,
          :liveness_key,
          :path,
          :port,
          :queue_prefix,
          :registered_instance_key,
          :server,
          :time_to_live,
        )
      end
    end
  end
end
