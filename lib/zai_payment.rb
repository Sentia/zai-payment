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
  end
end
