# frozen_string_literal: true

require "rack/test"
require "net/http"

RSpec.describe Resque::Plugins::Alive::Server do
  include Rack::Test::Methods

  describe "responses" do
    it "is successful when the Resque is alive" do
      stub_liveness(alive: true)

      get("/")

      expect(last_response).to be_ok
      expect(last_response.body).to eq("Alive key is present")
    end

    it "is an error when the Resque is not alive" do
      stub_liveness(alive: false)

      get("/")

      expect(last_response).to be_not_found
      expect(last_response.body).to eq("Alive key is absent")
    end

    it "is not found when given an unknown path" do
      get '/unknown-path'

      expect(last_response).to be_not_found
      expect(last_response.body).to eq("Received unknown path")
    end
  end

  it "can configure the port via ENV variables" do
    with_temporary_env("RESQUE_ALIVE_PORT" => '2345') do
      expect(described_class.port)
        .to eq('2345')
    end
  end

  it "can configure the application server via ENV variables" do
    with_temporary_env("RESQUE_ALIVE_SERVER" => "puma") do
      expect(described_class.server)
        .to eq("puma")
    end
  end

  it "can configure the path via ENV variables", :aggregate_failures do
    with_temporary_env("RESQUE_ALIVE_PATH" => "/resque-probe") do
      expect(described_class.path)
        .to eq("/resque-probe")

      stub_liveness(alive: true)

      get("/resque-probe")

      expect(last_response).to be_ok
      expect(last_response.body).to eq("Alive key is present")
    end
  end

  def app
    described_class
  end

  def stub_liveness(alive: )
    allow(Resque::Plugins::Alive)
      .to receive(:alive?)
      .and_return(alive)
  end
end
