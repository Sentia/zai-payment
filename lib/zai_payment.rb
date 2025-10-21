# frozen_string_literal: true

require 'faraday'
require_relative 'zai_payment/version'
require_relative 'zai_payment/config'
require_relative 'zai_payment/errors'
require_relative 'zai_payment/auth/token_provider'
require_relative 'zai_payment/auth/token_store'
require_relative 'zai_payment/auth/token_stores/memory_store'

module ZaiPayment
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end

    # Singleton auth token provider (uses default MemoryStore under the hood)
    def auth
      @auth ||= ZaiPayment::Auth::TokenProvider.new(config: config)
    end

    # --- Convenience one-liners ---
    def token            = auth.bearer_token
    def refresh_token!   = auth.refresh_token
    def clear_token!     = auth.clear_token
    def token_expiry     = auth.token_expiry
    def token_type       = auth.token_type
  end
end
