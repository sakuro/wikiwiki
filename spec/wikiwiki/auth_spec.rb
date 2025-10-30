# frozen_string_literal: true

RSpec.describe Wikiwiki::Auth do
  describe ".password" do
    it "creates Password instance with correct password" do
      auth = Wikiwiki::Auth.password(password: "test_password")
      expect(auth).to be_a(Wikiwiki::Auth::Password)
      expect(auth.password).to eq("test_password")
    end
  end

  describe ".api_key" do
    it "creates ApiKey instance with correct attributes" do
      auth = Wikiwiki::Auth.api_key(api_key_id: "key_id", secret: "key_secret")
      expect(auth).to be_a(Wikiwiki::Auth::ApiKey)
      expect(auth.api_key_id).to eq("key_id")
      expect(auth.secret).to eq("key_secret")
    end
  end
end
