# frozen_string_literal: true

require "rack"

module Resque
  module Plugins
    module Alive
      class Server
        class << self
          def run!
            handler = Rack::Handler.get(server)

            Signal.trap("TERM") { handler.shutdown }

            handler.run(self, Port: port, Host: '0.0.0.0')
          end

          def port
            config.port
          end

          def path
            config.path
          end

          def server
            config.server
          end

          def config
            Alive.config
          end

          def call(env)
            if Rack::Request.new(env).path != path
              [404, {}, ["Received unknown path"]]
            elsif Alive.alive?
              [200, {}, ["Alive key is present"]]
            else
              response = "Alive key is absent"
              Alive.logger.error(response)
              [404, {}, [response]]
            end
          end
        end
      end
    end
  end
end
