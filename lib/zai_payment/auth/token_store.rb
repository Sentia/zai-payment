# frozen_string_literal: true

module ZaiPayment
  module Auth
    class TokenStore
      Token = Struct.new(:value, :expires_at, keyword_init: true)

      def fetch = raise(NotImplementedError)
      def write(token) = raise(NotImplementedError)
      def clear = raise(NotImplementedError)
    end
  end
end
