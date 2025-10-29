# frozen_string_literal: true

RSpec.describe Wikiwiki::Auth::ApiKey do
  let(:api_key_id) { "api_key_123" }
  let(:secret) { "secret_456" }
  let(:auth) { Wikiwiki::Auth::ApiKey.new(api_key_id:, secret:) }

  describe "#endpoint" do
    it "returns 'auth'" do
      expect(auth.endpoint).to eq("auth")
    end
  end

  describe "#request_body" do
    it "returns hash with api_key_id and secret" do
      expect(auth.request_body).to eq({api_key_id: "api_key_123", secret: "secret_456"})
    end
  end

  describe "factory method" do
    it "can be created via Wikiwiki::Auth.api_key" do
      auth = Wikiwiki::Auth.api_key(api_key_id: "key_id", secret: "key_secret")
      expect(auth).to be_a(Wikiwiki::Auth::ApiKey)
      expect(auth.api_key_id).to eq("key_id")
      expect(auth.secret).to eq("key_secret")
    end
  end
end
