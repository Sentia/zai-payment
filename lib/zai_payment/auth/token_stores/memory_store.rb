# frozen_string_literal: true

require 'monitor'

module ZaiPayment
  module Auth
    module TokenStores
      class MemoryStore < TokenStore
        def initialize
          super
          @token = nil
          @monitor = Monitor.new
        end

        def fetch
          @monitor.synchronize { @token }
        end

        def write(token)
          @monitor.synchronize { @token = token }
        end

        def clear
          @monitor.synchronize { @token = nil }
        end
      end
    end
  end
end
