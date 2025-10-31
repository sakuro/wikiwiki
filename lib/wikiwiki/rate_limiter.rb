# frozen_string_literal: true

module Wikiwiki
  # Rate limiter with pluggable strategies
  #
  # @example Raise on limit
  #   limiter = Wikiwiki::RateLimiter.raise_on_limit([
  #     { window: 60, max_requests: 120 },     # 120 requests per minute
  #     { window: 3600, max_requests: 2000 }   # 2000 requests per hour
  #   ])
  #   limiter.acquire!  # raises RateLimitError if limit exceeded
  #
  # @example Wait on limit
  #   limiter = Wikiwiki::RateLimiter.wait_on_limit([
  #     { window: 60, max_requests: 120 }
  #   ])
  #   limiter.acquire!  # waits automatically if limit exceeded
  #
  # @example No limit
  #   limiter = Wikiwiki::RateLimiter.no_limit
  #   limiter.acquire!  # always succeeds immediately
  class RateLimiter
    # Default rate limits for Wikiwiki REST API
    WIKIWIKI_API_LIMITS = [
      {window: 60, max_requests: 120},     # 120 requests per minute
      {window: 3600, max_requests: 2000}   # 2000 requests per hour
    ].freeze
    public_constant :WIKIWIKI_API_LIMITS

    # Create a rate limiter that raises error when limit is exceeded
    #
    # @param limits [Array<Hash>] array of limit configurations
    # @option limits [Integer] :window time window in seconds
    # @option limits [Integer] :max_requests maximum requests allowed in the window
    # @return [RateLimiter]
    # @raise [ArgumentError] if limits is empty
    def self.raise_on_limit(limits)
      raise ArgumentError, "limits cannot be empty (use .no_limit for no rate limiting)" if limits.empty?
      new(limits, Strategy::Raise.new)
    end

    # Create a rate limiter that waits when limit is exceeded
    #
    # @param limits [Array<Hash>] array of limit configurations
    # @option limits [Integer] :window time window in seconds
    # @option limits [Integer] :max_requests maximum requests allowed in the window
    # @return [RateLimiter]
    # @raise [ArgumentError] if limits is empty
    def self.wait_on_limit(limits)
      raise ArgumentError, "limits cannot be empty (use .no_limit for no rate limiting)" if limits.empty?
      new(limits, Strategy::Wait.new)
    end

    # Create a null rate limiter that never limits
    #
    # @return [RateLimiter]
    def self.no_limit = new([], Strategy::Null.new)

    # Create a rate limiter with default limits (120 requests/min, 2000 requests/hour)
    #
    # These are the rate limits for the Wikiwiki REST API.
    #
    # @return [RateLimiter]
    def self.default = wait_on_limit(WIKIWIKI_API_LIMITS)

    private_class_method :new

    # @param limits [Array<Hash>] array of limit configurations
    # @param strategy [Strategy] rate limiting strategy
    def initialize(limits, strategy)
      @windows = limits.map {|limit| SlidingWindow.new(**limit) }
      @mutex = Mutex.new
      @strategy = strategy
    end

    # Acquire permission to make a request
    #
    # Behavior depends on the strategy:
    # - raise_on_limit: raises RateLimitError if limit exceeded
    # - wait_on_limit: waits until request can be made
    # - no_limit: always succeeds immediately
    #
    # @return [void]
    # @raise [RateLimitError] if rate limit is exceeded (with raise strategy)
    def acquire!
      @strategy.acquire!(self)
    end

    # Get time in seconds until next request can be made
    #
    # @return [Float] seconds to wait (0.0 if request can be made now)
    def wait_time_until_available
      @mutex.synchronize do
        @windows.map(&:wait_time).max || 0.0
      end
    end

    # Check if a request can be made without exceeding any limits
    #
    # @return [Boolean] true if request is allowed
    def can_request?
      @windows.all?(&:can_request?)
    end

    # Record a new request across all window limiters
    #
    # @return [void]
    def record!
      @windows.each(&:record!)
    end

    # Get maximum wait time across all window limiters
    #
    # @return [Float, nil] seconds to wait
    def wait_time
      @windows.map(&:wait_time).max
    end

    attr_reader :mutex
  end

  # Rate limiting strategies
  module Strategy
    # Strategy that raises error when limit is exceeded
    class Raise
      # @param limiter [RateLimiter]
      # @return [void]
      # @raise [RateLimitError] if rate limit is exceeded
      def acquire!(limiter)
        limiter.mutex.synchronize do
          raise RateLimitError, "Rate limit exceeded" unless limiter.can_request?

          limiter.record!
        end
      end
    end

    # Strategy that waits when limit is exceeded
    class Wait
      # @param limiter [RateLimiter]
      # @return [void]
      def acquire!(limiter)
        limiter.mutex.synchronize do
          until limiter.can_request?
            wait_time = limiter.wait_time
            sleep wait_time if wait_time&.positive?
          end
          limiter.record!
        end
      end
    end

    # Strategy that never limits (null object pattern)
    class Null
      # @param limiter [RateLimiter]
      # @return [void]
      def acquire!(limiter)
        # no-op
      end
    end
  end
end
