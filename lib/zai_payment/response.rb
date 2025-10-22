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
      body.is_a?(Hash) ? body['webhooks'] || body : body
    end

    # Get pagination or metadata info
    def meta
      body.is_a?(Hash) ? body['meta'] : nil
    end

    private

    def check_for_errors!
      return if success?

      error_message = extract_error_message

      case status
      when 400
        raise Errors::BadRequestError, error_message
      when 401
        raise Errors::UnauthorizedError, error_message
      when 403
        raise Errors::ForbiddenError, error_message
      when 404
        raise Errors::NotFoundError, error_message
      when 422
        raise Errors::ValidationError, error_message
      when 429
        raise Errors::RateLimitError, error_message
      when 500..599
        raise Errors::ServerError, error_message
      else
        raise Errors::ApiError, error_message
      end
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
