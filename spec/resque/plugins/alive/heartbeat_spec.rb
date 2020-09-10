# frozen_string_literal: true

RSpec.describe Resque::Plugins::Alive::Heartbeat do
  it "registers the heartbeat" do
    expect { described_class.perform }
      .to change { Resque::Plugins::Alive.alive? }
      .from(false)
      .to(true)
  end

  it "enqueues the next heartbeat" do
    expect { described_class.perform }
      .to change { Resque.size(described_class.current_queue) }
      .from(0)
      .to(1)
  end
end
