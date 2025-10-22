# frozen_string_literal: true

module ZaiPayment
  module Errors
    # Base error class
    class Error < StandardError; end

    # Authentication errors
    class AuthError < Error; end

    # Configuration errors
    class ConfigurationError < Error; end

    # API errors
    class ApiError < Error; end
    class BadRequestError < ApiError; end
    class UnauthorizedError < ApiError; end
    class ForbiddenError < ApiError; end
    class NotFoundError < ApiError; end
    class ValidationError < ApiError; end
    class RateLimitError < ApiError; end
    class ServerError < ApiError; end

    # Network errors
    class TimeoutError < Error; end
    class ConnectionError < Error; end
  end
end
