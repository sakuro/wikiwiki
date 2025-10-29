# frozen_string_literal: true

RSpec.describe Wikiwiki::SlidingWindow do
  let(:limiter) { Wikiwiki::SlidingWindow.new(window: 1, max_requests: 3) }

  describe "#can_request?" do
    it "returns true when under limit" do
      expect(limiter.can_request?).to be true
    end

    it "returns false when at limit" do
      3.times { limiter.record! }
      expect(limiter.can_request?).to be false
    end

    it "returns true after window expires" do
      3.times { limiter.record! }
      expect(limiter.can_request?).to be false
      sleep 1.1
      expect(limiter.can_request?).to be true
    end
  end

  describe "#record!" do
    it "records request timestamp and affects limit" do
      3.times { limiter.record! }
      expect(limiter.can_request?).to be false
    end
  end

  describe "cleanup" do
    it "removes old requests outside the window" do
      3.times { limiter.record! }
      expect(limiter.can_request?).to be false
      sleep 1.1
      expect(limiter.can_request?).to be true
    end
  end

  describe "#wait_time" do
    it "returns 0.0 when under limit" do
      expect(limiter.wait_time).to eq(0.0)
    end

    it "returns 0.0 after recording some requests but still under limit" do
      2.times { limiter.record! }
      expect(limiter.wait_time).to eq(0.0)
    end

    it "returns wait time when at limit" do
      3.times { limiter.record! }
      wait_time = limiter.wait_time
      expect(wait_time).to be > 0.0
      expect(wait_time).to be <= 1.0
    end

    it "returns 0.0 after window expires" do
      3.times { limiter.record! }
      sleep 1.1
      expect(limiter.wait_time).to eq(0.0)
    end
  end
end
