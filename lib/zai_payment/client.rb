# frozen_string_literal: true

require 'faraday'

module ZaiPayment
  # Base API client that handles HTTP requests to Zai API
  class Client
    attr_reader :config, :token_provider, :base_endpoint

    def initialize(config: nil, token_provider: nil, base_endpoint: nil)
      @config = config || ZaiPayment.config
      @token_provider = token_provider || ZaiPayment.auth
      @base_endpoint = base_endpoint
    end

    # Perform a GET request
    #
    # @param path [String] the API endpoint path
    # @param params [Hash] query parameters
    # @return [Response] the API response
    def get(path, params: {})
      request(:get, path, params: params)
    end

    # Perform a POST request
    #
    # @param path [String] the API endpoint path
    # @param body [Hash] request body
    # @return [Response] the API response
    def post(path, body: {})
      request(:post, path, body: body)
    end

    # Perform a PATCH request
    #
    # @param path [String] the API endpoint path
    # @param body [Hash] request body
    # @return [Response] the API response
    def patch(path, body: {})
      request(:patch, path, body: body)
    end

    # Perform a DELETE request
    #
    # @param path [String] the API endpoint path
    # @return [Response] the API response
    def delete(path)
      request(:delete, path)
    end

    private

    def request(method, path, params: {}, body: {})
      response = connection.public_send(method) do |req|
        req.url path
        req.headers['Authorization'] = token_provider.bearer_token
        req.params = params if params.any?
        req.body = body if body.any?
      end

      Response.new(response)
    rescue Faraday::Error => e
      handle_faraday_error(e)
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      handle_net_timeout_error(e)
    end

    def connection
      @connection ||= build_connection
    end

    def build_connection
      Faraday.new do |faraday|
        configure_connection(faraday)
      end
    end

    def configure_connection(faraday)
      faraday.url_prefix = base_url
      apply_headers(faraday)
      apply_middleware(faraday)
      apply_timeouts(faraday)
      faraday.adapter Faraday.default_adapter
    end

    def apply_headers(faraday)
      # Authorization header is set per-request to ensure fresh tokens
      faraday.headers['Content-Type'] = 'application/json'
      faraday.headers['Accept'] = 'application/json'
    end

    def apply_middleware(faraday)
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
    end

    def apply_timeouts(faraday)
      set_timeout_option(faraday, :timeout, config.timeout)
      set_timeout_option(faraday, :open_timeout, config.open_timeout)
      set_timeout_option(faraday, :read_timeout, config.read_timeout)
    end

    def set_timeout_option(faraday, option, value)
      faraday.options.public_send("#{option}=", value) if value
    end

    def base_url
      # Use specified base_endpoint or default to va_base
      # Users API uses core_base endpoint
      # Webhooks API uses va_base endpoint
      if base_endpoint
        config.endpoints[base_endpoint]
      else
        config.endpoints[:va_base]
      end
    end

    def handle_faraday_error(error)
      case error
      when Faraday::TimeoutError
        raise Errors::TimeoutError, "Request timed out: #{error.message}"
      when Faraday::ConnectionFailed
        raise Errors::ConnectionError, "Connection failed: #{error.message}"
      when Faraday::ClientError
        raise Errors::ApiError, "Client error: #{error.message}"
      else
        raise Errors::ApiError, "Request failed: #{error.message}"
      end
    end

    def handle_net_timeout_error(error)
      raise Errors::TimeoutError, "Request timed out: #{error.class.name} with #{error.message}"
    end
  end
end
