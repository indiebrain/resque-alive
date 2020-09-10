# frozen_string_literal: true

module Resque
  module Plugins
    module Alive
      module Support
        module Redis
          def with_mock_redis(&block)
            mock_redis = MockRedis.new
            allow(Resque::Plugins::Alive)
              .to receive(:redis)
              .and_return(mock_redis)

            block.call(mock_redis)
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Resque::Plugins::Alive::Support::Redis
end
