# frozen_string_literal: true

module Wikiwiki
  # Sliding window algorithm for rate limiting
  class SlidingWindow
    # Initialize a new window limiter
    #
    # @param window [Integer] time window in seconds
    # @param max_requests [Integer] maximum requests allowed in the window
    def initialize(window:, max_requests:)
      @window = window
      @max_requests = max_requests
      @requests = []
    end

    # Check if a request can be made without exceeding the limit
    #
    # @return [Boolean] true if request is allowed
    def can_request?
      cleanup!
      @requests.size < @max_requests
    end

    # Record a new request timestamp
    #
    # @return [void]
    def record! = (@requests << Time.now)

    # Get time in seconds until next request can be made
    #
    # @return [Float] seconds to wait (0.0 if request can be made now)
    def wait_time
      cleanup!
      return 0.0 if @requests.size < @max_requests

      # Time until oldest request expires
      oldest = @requests.first
      time_until_expiry = @window - (Time.now - oldest)
      [time_until_expiry, 0.0].max
    end

    private def cleanup!
      cutoff = Time.now - @window
      @requests.reject! {|timestamp| timestamp < cutoff }
    end
  end
end
