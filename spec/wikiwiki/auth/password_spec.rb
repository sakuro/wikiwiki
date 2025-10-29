# frozen_string_literal: true

RSpec.describe Wikiwiki::Auth::Password do
  let(:password) { "admin_password" }
  let(:auth) { Wikiwiki::Auth::Password.new(password:) }

  describe "#endpoint" do
    it "returns 'auth'" do
      expect(auth.endpoint).to eq("auth")
    end
  end

  describe "#request_body" do
    it "returns hash with password" do
      expect(auth.request_body).to eq({password: "admin_password"})
    end
  end

  describe "factory method" do
    it "can be created via Wikiwiki::Auth.password" do
      auth = Wikiwiki::Auth.password(password: "test_password")
      expect(auth).to be_a(Wikiwiki::Auth::Password)
      expect(auth.password).to eq("test_password")
    end
  end
end
