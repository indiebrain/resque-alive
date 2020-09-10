# frozen_string_literal: true

module Resque
  module Plugins
    module Alive
      module Support
        module Env
          def with_temporary_env(tmp_env, &block)
            env = ENV.to_hash
            ENV.merge!(tmp_env)

            Resque::Plugins::Alive::Config.instance.set_defaults
            block.call
          ensure
            ENV.replace(env)
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Resque::Plugins::Alive::Support::Env
end
