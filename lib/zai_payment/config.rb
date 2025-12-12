# frozen_string_literal: true

module ZaiPayment
  class Config
    attr_accessor :environment, :client_id, :client_secret, :scope,
                  :timeout, :open_timeout, :read_timeout

    def initialize
      @environment  = :prelive # or :production
      @client_id    = nil
      @client_secret = nil
      @scope = nil
      @timeout = 30      # General timeout - increased from 10 to 30 seconds
      @open_timeout = 10 # Connection open timeout
      @read_timeout = 30 # Read timeout - new separate configuration
    end

    def validate!
      raise Errors::ConfigurationError, 'client_id is required' if client_id.nil? || client_id.empty?
      raise Errors::ConfigurationError, 'client_secret is required' if client_secret.nil? || client_secret.empty?
      raise Errors::ConfigurationError, 'scope is required' if scope.nil? || scope.empty?
    end

    def endpoints
      case environment.to_sym
      when :prelive
        {
          core_base: 'https://test.api.promisepay.com',
          va_base: 'https://sandbox.au-0000.api.assemblypay.com',
          auth_base: 'https://au-0000.sandbox.auth.assemblypay.com'
        }
      when :production
        {
          core_base: 'https://au-0000.api.assemblypay.com',
          va_base: 'https://secure.api.promisepay.com',
          auth_base: 'https://au-0000.auth.assemblypay.com'
        }
      else
        raise "Unknown environment: #{environment}"
      end
    end

    # Returns the appropriate webhook base endpoint based on environment
    # Production uses core_base, prelive uses va_base
    def webhook_base_endpoint
      case environment.to_sym
      when :production
        :core_base
      when :prelive
        :va_base
      else
        raise "Unknown environment: #{environment}"
      end
    end
  end
end
