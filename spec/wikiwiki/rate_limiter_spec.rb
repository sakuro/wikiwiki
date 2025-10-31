# frozen_string_literal: true

RSpec.describe Wikiwiki::RateLimiter do
  describe ".raise_on_limit" do
    it "raises ArgumentError when limits is empty" do
      expect {
        Wikiwiki::RateLimiter.raise_on_limit([])
      }.to raise_error(ArgumentError, "limits cannot be empty (use .no_limit for no rate limiting)")
    end

    let(:limiter) { Wikiwiki::RateLimiter.raise_on_limit([{window: 1, max_requests: 3}]) }

    describe "#acquire!" do
      it "allows requests within limit" do
        expect { limiter.acquire! }.not_to raise_error
        expect { limiter.acquire! }.not_to raise_error
        expect { limiter.acquire! }.not_to raise_error
      end

      it "raises RateLimitError when limit is exceeded" do
        3.times { limiter.acquire! }
        expect { limiter.acquire! }.to raise_error(Wikiwiki::RateLimitError, "Rate limit exceeded")
      end

      it "allows requests after time window expires" do
        3.times { limiter.acquire! }
        sleep 1.1
        expect { limiter.acquire! }.not_to raise_error
      end
    end

    context "with multiple time window limits" do
      let(:limiter) do
        Wikiwiki::RateLimiter.raise_on_limit(
          [
            {window: 1, max_requests: 3}, # 3 per second
            {window: 2, max_requests: 5} # 5 per 2 seconds
          ]
        )
      end

      it "allows requests when both limits are satisfied" do
        3.times { expect { limiter.acquire! }.not_to raise_error }
      end

      it "raises error when first limit is exceeded" do
        3.times { limiter.acquire! }
        expect { limiter.acquire! }.to raise_error(Wikiwiki::RateLimitError)
      end

      it "raises error when second limit is exceeded" do
        3.times { limiter.acquire! }
        sleep 1.1
        2.times { limiter.acquire! }
        expect { limiter.acquire! }.to raise_error(Wikiwiki::RateLimitError)
      end

      it "allows requests after longer window expires" do
        5.times do
          limiter.acquire!
        rescue
          nil
        end
        sleep 2.1
        expect { limiter.acquire! }.not_to raise_error
      end
    end

    context "with thread safety" do
      let(:limiter) { Wikiwiki::RateLimiter.raise_on_limit([{window: 1, max_requests: 10}]) }

      it "safely handles concurrent requests" do
        threads = Array.new(20) {
          Thread.new do
            limiter.acquire!
            true
          rescue Wikiwiki::RateLimitError
            false
          end
        }

        results = threads.map(&:value)
        successful_requests = results.count(true)

        # Exactly 10 requests should succeed
        expect(successful_requests).to eq(10)
      end
    end

    describe "#wait_time_until_available" do
      let(:limiter) { Wikiwiki::RateLimiter.raise_on_limit([{window: 1, max_requests: 3}]) }

      it "returns 0.0 when under limit" do
        expect(limiter.wait_time_until_available).to eq(0.0)
      end

      it "returns wait time when at limit" do
        3.times { limiter.acquire! }
        wait_time = limiter.wait_time_until_available
        expect(wait_time).to be > 0.0
        expect(wait_time).to be <= 1.0
      end

      context "with multiple windows" do
        let(:limiter) do
          Wikiwiki::RateLimiter.raise_on_limit(
            [
              {window: 1, max_requests: 2},
              {window: 2, max_requests: 3}
            ]
          )
        end

        it "returns maximum wait time across all limiters" do
          2.times { limiter.acquire! }
          sleep 1.1
          limiter.acquire!
          wait_time = limiter.wait_time_until_available
          expect(wait_time).to be > 0.0
          expect(wait_time).to be <= 2.0
        end
      end
    end
  end

  describe ".wait_on_limit" do
    it "raises ArgumentError when limits is empty" do
      expect {
        Wikiwiki::RateLimiter.wait_on_limit([])
      }.to raise_error(ArgumentError, "limits cannot be empty (use .no_limit for no rate limiting)")
    end

    let(:limiter) { Wikiwiki::RateLimiter.wait_on_limit([{window: 1, max_requests: 2}]) }

    describe "#acquire!" do
      it "waits and succeeds when limit is exceeded" do
        2.times { limiter.acquire! }
        start_time = Time.now
        expect { limiter.acquire! }.not_to raise_error
        elapsed = Time.now - start_time
        expect(elapsed).to be >= 0.9
      end

      it "returns immediately when under limit" do
        start_time = Time.now
        expect { limiter.acquire! }.not_to raise_error
        elapsed = Time.now - start_time
        expect(elapsed).to be < 0.1
      end
    end

    context "with realistic API limits" do
      let(:limiter) do
        Wikiwiki::RateLimiter.wait_on_limit(
          [
            {window: 60, max_requests: 120}, # 120 per minute
            {window: 3600, max_requests: 2000} # 2000 per hour
          ]
        )
      end

      it "allows many requests within limits" do
        100.times { expect { limiter.acquire! }.not_to raise_error }
      end
    end

    describe "#wait_time_until_available" do
      let(:limiter) { Wikiwiki::RateLimiter.wait_on_limit([{window: 1, max_requests: 3}]) }

      it "returns 0.0 when under limit" do
        expect(limiter.wait_time_until_available).to eq(0.0)
      end

      it "returns wait time when at limit" do
        3.times { limiter.acquire! }
        wait_time = limiter.wait_time_until_available
        expect(wait_time).to be > 0.0
        expect(wait_time).to be <= 1.0
      end
    end
  end

  describe ".no_limit" do
    let(:limiter) { Wikiwiki::RateLimiter.no_limit }

    describe "#acquire!" do
      it "never raises error" do
        expect { 1000.times { limiter.acquire! } }.not_to raise_error
      end

      it "executes instantly without waiting" do
        start_time = Time.now
        1000.times { limiter.acquire! }
        elapsed = Time.now - start_time
        expect(elapsed).to be < 0.1
      end
    end

    describe "#wait_time_until_available" do
      it "always returns 0.0" do
        1000.times { limiter.acquire! }
        expect(limiter.wait_time_until_available).to eq(0.0)
      end
    end
  end
end
