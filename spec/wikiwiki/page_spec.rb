# frozen_string_literal: true

RSpec.describe Wikiwiki::Page do
  let(:timestamp) { Time.new(2022, 1, 1, 0, 0, 0, "+09:00") }
  let(:page) do
    Wikiwiki::Page.new(
      name: "FrontPage",
      source: "TITLE:Welcome\n# Content",
      timestamp:
    )
  end

  describe "#name" do
    it "returns the page name" do
      expect(page.name).to eq("FrontPage")
    end
  end

  describe "#source" do
    it "returns the page source" do
      expect(page.source).to eq("TITLE:Welcome\n# Content")
    end
  end

  describe "#timestamp" do
    it "returns the page timestamp as Time object" do
      expect(page.timestamp).to eq(timestamp)
      expect(page.timestamp).to be_a(Time)
    end
  end
end
