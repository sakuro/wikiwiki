# frozen_string_literal: true

RSpec.describe Wikiwiki::Auth::Token do
  describe ".new" do
    it "creates a token auth object with the given token" do
      token = "jwt_token_123"
      auth = Wikiwiki::Auth::Token.new(token:)

      expect(auth.token).to eq(token)
    end
  end

  describe "#to_h" do
    it "returns a hash with token key" do
      token = "jwt_token_123"
      auth = Wikiwiki::Auth::Token.new(token:)

      expect(auth.to_h).to eq({token: "jwt_token_123"})
    end
  end
end
