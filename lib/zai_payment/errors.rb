# frozen_string_literal: true

module ZaiPayment
  module Errors
    class Error < StandardError; end
    class AuthError < Error; end
    class ConfigurationError < Error; end
  end
end
