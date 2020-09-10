# frozen_string_literal: true

RSpec.describe Resque::Plugins::Alive do
  it "is a valid Resque Plugin" do
    Resque::Plugin.lint(Resque::Plugins::Alive)
  end

  it "has a version number" do
    expect(Resque::Plugins::Alive::VERSION)
      .not_to be nil
  end

  describe "configuration" do
    def default_configuration
      described_class.config
    end

    it "is enabled by default" do
      expect(Resque::Plugins::Alive.enabled?)
        .to eq(true)
    end

    it "can be disabled programatically" do
      default_configuration.enabled = false

      expect(Resque::Plugins::Alive.enabled?)
        .to eq(false)
    end

    it "can be disabled via the RESQUE_ALIVE_DISABLED ENV var" do
      with_temporary_env("RESQUE_ALIVE_DISABLED" => "true") do
        expect(Resque::Plugins::Alive.enabled?)
          .to eq(false)
      end
    end

    it "has a default #port" do
      expect(default_configuration.port)
        .to eq(7433)
    end

    it "can set a port" do
      default_configuration.port = 9999

      expect(default_configuration.port)
        .to eq(9999)
    end

    it "has a default #liveness_key" do
      expect(default_configuration.liveness_key)
        .to eq("RESQUE::LIVENESS_PROBE_TIMESTAMP")
    end

    it "can set liveness_key" do
      default_configuration.liveness_key = "new-liveness-key"

      expect(default_configuration.liveness_key)
        .to eq("new-liveness-key")
    end

    it "has a default #time_to_live" do
      expect(default_configuration.time_to_live)
        .to eq(10 * 60)
    end

    it "can set time_to_live" do
      default_configuration.time_to_live = 2 * 60

      expect(default_configuration.time_to_live)
        .to eq(2 * 60)
    end

    it "has a default #callback" do
      expect(default_configuration.callback.call)
        .to eq(nil)
    end

    it "can set callback" do
      default_configuration.callback = -> { "expected-callback-result" }

      expect(default_configuration.callback.call)
        .to eq("expected-callback-result")
    end

    it "has a default #queue_prefix" do
      expect(default_configuration.queue_prefix)
        .to eq(:resque_alive)
    end

    it "can set queue_prefix" do
      default_configuration.queue_prefix = :expected_queue_prefix

      expect(default_configuration.queue_prefix)
        .to eq(:expected_queue_prefix)
    end

    it "can programatically alter config via setup" do
      described_class.setup do |config|
        config.port = 11111
      end

      expect(described_class.config.port)
        .to eq(11111)
    end

    it "configures the port from the RESQUE_ALIVE_PORT ENV var" do
      with_temporary_env("RESQUE_ALIVE_PORT" => "9876") do
        Resque::Plugins::Alive.config.set_defaults

        expect(default_configuration.port)
          .to eq('9876')
      end
    end

    it "configures the path from the RESQUE_ALIVE_PATH ENV var" do
      with_temporary_env("RESQUE_ALIVE_PATH" => "/expected_path") do
        Resque::Plugins::Alive.config.set_defaults

        expect(default_configuration.path)
          .to eq('/expected_path')
      end
    end
  end

  it "stores the alive key with a time-to-live" do
    with_mock_redis do
      redis = Resque::Plugins::Alive.redis
      time_to_live = redis.ttl(Resque::Plugins::Alive.current_liveness_key)
      expect(time_to_live)
        .to eq(Resque::Plugins::Alive::Redis::TTL_EXPIRED)

      expect { Resque::Plugins::Alive.store_alive_key }
        .to change { redis.ttl(Resque::Plugins::Alive.current_liveness_key) }
              .from(Resque::Plugins::Alive::Redis::TTL_EXPIRED)
              .to(Resque::Plugins::Alive.config.time_to_live)
    end
  end

  it "has a current_liveness_key" do
    with_temporary_env("HOSTNAME" => "expected-hostname") do
      expect(described_class.current_liveness_key)
        .to include("::expected-hostname")
    end
  end

  it "has a hostname" do
    with_temporary_env("HOSTNAME" => "expected-hostname") do
      expect(described_class.hostname)
        .to eq("expected-hostname")
    end
  end

  it "is alive when the alive_key is present" do
    with_mock_redis do
      Resque::Plugins::Alive.store_alive_key

      expect(Resque::Plugins::Alive.alive?)
        .to eq(true)
    end
  end

  it "is not alive when the alive_key is absent" do
    with_mock_redis do
      expect(Resque::Plugins::Alive.alive?)
        .to be false
    end
  end

  it "has collection of registered instances" do
    with_temporary_env("HOSTNAME" => "expected-hostname") do
      expect(Resque::Plugins::Alive.registered_instances).to eq []

      expect { Resque::Plugins::Alive.register_current_instance }
        .to change { Resque::Plugins::Alive.registered_instances }
              .from([])
              .to([registration_key("expected-hostname")])
    end
  end

  it "can unregister the current instance" do
    with_temporary_env("HOSTNAME" => "expected-hostname") do
      Resque::Plugins::Alive.register_current_instance

      expect { Resque::Plugins::Alive.unregister_current_instance }
        .to change { Resque::Plugins::Alive.registered_instances }
              .from([registration_key("expected-hostname")])
              .to([])
    end
  end

  def registration_key(hostname)
    "#{described_class.config.registered_instance_key}::#{hostname}"
  end
end
