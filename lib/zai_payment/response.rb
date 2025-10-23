# frozen_string_literal: true

module ZaiPayment
  # Wrapper for API responses
  class Response
    attr_reader :status, :body, :headers, :raw_response

    def initialize(faraday_response)
      @raw_response = faraday_response
      @status = faraday_response.status
      @body = faraday_response.body
      @headers = faraday_response.headers

      check_for_errors!
    end

    # Check if the response was successful (2xx status)
    def success?
      (200..299).cover?(status)
    end

    # Check if the response was a client error (4xx status)
    def client_error?
      (400..499).cover?(status)
    end

    # Check if the response was a server error (5xx status)
    def server_error?
      (500..599).cover?(status)
    end

    # Get the data from the response body
    def data
      body.is_a?(Hash) ? body['webhooks'] || body['users'] || body : body
    end

    # Get pagination or metadata info
    def meta
      body.is_a?(Hash) ? body['meta'] : nil
    end

    ERROR_STATUS_MAP = {
      400 => Errors::BadRequestError,
      401 => Errors::UnauthorizedError,
      403 => Errors::ForbiddenError,
      404 => Errors::NotFoundError,
      422 => Errors::ValidationError,
      429 => Errors::RateLimitError
    }.merge((500..599).to_h { |code| [code, Errors::ServerError] }).freeze

    private

    def check_for_errors!
      return if success?

      raise_appropriate_error
    end

    def raise_appropriate_error
      error_message = extract_error_message
      error_class = error_class_for_status
      raise error_class, error_message
    end

    def error_class_for_status
      ERROR_STATUS_MAP.fetch(status, Errors::ApiError)
    end

    def extract_error_message
      if body.is_a?(Hash)
        body['error'] || body['message'] || body['errors']&.join(', ') || "HTTP #{status}"
      else
        "HTTP #{status}: #{body}"
      end
    end
  end
end
