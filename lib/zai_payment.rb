# frozen_string_literal: true

require 'faraday'
require 'uri'
require_relative 'zai_payment/version'
require_relative 'zai_payment/config'
require_relative 'zai_payment/errors'
require_relative 'zai_payment/auth/token_provider'
require_relative 'zai_payment/auth/token_store'
require_relative 'zai_payment/auth/token_stores/memory_store'
require_relative 'zai_payment/client'
require_relative 'zai_payment/response'
require_relative 'zai_payment/resources/webhook'
require_relative 'zai_payment/resources/user'
require_relative 'zai_payment/resources/item'
require_relative 'zai_payment/resources/token_auth'
require_relative 'zai_payment/resources/bank_account'
require_relative 'zai_payment/resources/bpay_account'
require_relative 'zai_payment/resources/batch_transaction'
require_relative 'zai_payment/resources/wallet_account'
require_relative 'zai_payment/resources/virtual_account'

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

    # --- Resource accessors ---
    # @return [ZaiPayment::Resources::Webhook] webhook resource instance
    def webhooks
      @webhooks ||= Resources::Webhook.new
    end

    # @return [ZaiPayment::Resources::User] user resource instance
    def users
      @users ||= Resources::User.new(client: Client.new(base_endpoint: :core_base))
    end

    # @return [ZaiPayment::Resources::Item] item resource instance
    def items
      @items ||= Resources::Item.new(client: Client.new(base_endpoint: :core_base))
    end

    # @return [ZaiPayment::Resources::TokenAuth] token_auth resource instance
    def token_auths
      @token_auths ||= Resources::TokenAuth.new(client: Client.new(base_endpoint: :core_base))
    end

    # @return [ZaiPayment::Resources::BankAccount] bank_account resource instance
    def bank_accounts
      @bank_accounts ||= Resources::BankAccount.new(client: Client.new(base_endpoint: :core_base))
    end

    # @return [ZaiPayment::Resources::BpayAccount] bpay_account resource instance
    def bpay_accounts
      @bpay_accounts ||= Resources::BpayAccount.new(client: Client.new(base_endpoint: :core_base))
    end

    # @return [ZaiPayment::Resources::BatchTransaction] batch_transaction resource instance (prelive only)
    def batch_transactions
      @batch_transactions ||= Resources::BatchTransaction.new(client: Client.new(base_endpoint: :core_base))
    end

    # @return [ZaiPayment::Resources::WalletAccount] wallet_account resource instance
    def wallet_accounts
      @wallet_accounts ||= Resources::WalletAccount.new(client: Client.new(base_endpoint: :core_base))
    end

    # @return [ZaiPayment::Resources::VirtualAccount] virtual_account resource instance
    def virtual_accounts
      @virtual_accounts ||= Resources::VirtualAccount.new
    end
  end
end
