# frozen_string_literal: true

RSpec.describe Wikiwiki::Auth::Password do
  let(:password) { "admin_password" }
  let(:auth) { Wikiwiki::Auth::Password.new(password:) }

  describe "#to_h" do
    it "returns hash with password" do
      expect(auth.to_h).to eq({password: "admin_password"})
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
