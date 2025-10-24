# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ZaiPayment::Auth::TokenStores::MemoryStore do
  let(:store) { described_class.new }

  describe '#initialize' do
    it 'creates a new memory store' do
      expect(store).to be_a(described_class)
    end

    it 'inherits from TokenStore' do
      expect(store).to be_a(ZaiPayment::Auth::TokenStore)
    end

    it 'initializes with no token' do
      expect(store.fetch).to be_nil
    end
  end

  describe '#fetch' do
    context 'when no token has been written' do
      it 'returns nil' do
        expect(store.fetch).to be_nil
      end
    end

    context 'when a token has been written' do
      let(:token) do
        ZaiPayment::Auth::TokenStore::Token.new(
          value: 'test_token_value',
          expires_at: Time.now + 3600,
          type: 'Bearer'
        )
      end

      before do
        store.write(token)
      end

      it 'returns the stored token' do
        expect(store.fetch).to eq(token)
      end

      it 'returns the same token object' do
        expect(store.fetch).to be(token)
      end
    end

    context 'when token has been cleared' do
      let(:token) do
        ZaiPayment::Auth::TokenStore::Token.new(
          value: 'test_token_value',
          expires_at: Time.now + 3600,
          type: 'Bearer'
        )
      end

      before do
        store.write(token)
        store.clear
      end

      it 'returns nil' do
        expect(store.fetch).to be_nil
      end
    end
  end

  describe '#write' do
    let(:token) do
      ZaiPayment::Auth::TokenStore::Token.new(
        value: 'new_token_value',
        expires_at: Time.now + 7200,
        type: 'Bearer'
      )
    end

    let(:old_token) do
      ZaiPayment::Auth::TokenStore::Token.new(
        value: 'old_token_value',
        expires_at: Time.now + 1800,
        type: 'Bearer'
      )
    end

    it 'stores the token' do
      store.write(token)
      expect(store.fetch).to eq(token)
    end

    it 'overwrites previously stored token' do
      store.write(old_token)
      store.write(token)

      expect(store.fetch).to eq(token)
      expect(store.fetch).not_to eq(old_token)
    end

    it 'returns the written token' do
      result = store.write(token)
      expect(result).to eq(token)
    end
  end

  describe '#clear' do
    let(:token) do
      ZaiPayment::Auth::TokenStore::Token.new(
        value: 'token_to_clear',
        expires_at: Time.now + 3600,
        type: 'Bearer'
      )
    end

    context 'when a token exists' do
      before do
        store.write(token)
      end

      it 'removes the stored token' do
        store.clear
        expect(store.fetch).to be_nil
      end

      it 'returns nil' do
        result = store.clear
        expect(result).to be_nil
      end
    end

    context 'when no token exists' do
      it 'does not raise an error' do
        expect { store.clear }.not_to raise_error
      end

      it 'returns nil' do
        result = store.clear
        expect(result).to be_nil
      end
    end

    context 'when called multiple times' do
      before do
        store.write(token)
      end

      it 'can be called multiple times without error' do
        expect do
          store.clear
          store.clear
          store.clear
        end.not_to raise_error
      end
    end
  end

  describe 'thread safety' do
    let(:bearer_token) do
      ZaiPayment::Auth::TokenStore::Token.new(
        value: 'bearer_token_value',
        expires_at: Time.now + 3600,
        type: 'Bearer'
      )
    end

    def create_token(index)
      ZaiPayment::Auth::TokenStore::Token.new(
        value: "token_#{index}",
        expires_at: Time.now + 3600,
        type: 'Bearer'
      )
    end

    def run_threads(threads)
      threads.each(&:join)
    end

    context 'with concurrent writes' do
      it 'completes all writes without errors' do
        threads = Array.new(10) do |i|
          Thread.new { store.write(create_token(i)) }
        end
        run_threads(threads)

        expect(store.fetch).to be_a(ZaiPayment::Auth::TokenStore::Token)
      end
    end

    context 'with concurrent reads' do
      before { store.write(bearer_token) }

      it 'returns consistent results' do
        results = []
        threads = Array.new(10) { Thread.new { results << store.fetch } }
        run_threads(threads)

        expect(results).to all(eq(bearer_token))
      end
    end

    context 'with concurrent reads and writes' do
      it 'maintains data integrity' do
        writers = Array.new(5) { |i| Thread.new { store.write(create_token(i)) } }
        readers = Array.new(5) { Thread.new { store.fetch } }
        run_threads(writers + readers)

        expect { store.fetch }.not_to raise_error
      end
    end

    context 'with concurrent clears' do
      before { store.write(bearer_token) }

      it 'clears the token successfully' do
        threads = Array.new(10) { Thread.new { store.clear } }
        run_threads(threads)

        expect(store.fetch).to be_nil
      end
    end

    context 'with mixed operations' do
      def perform_operation(index)
        case index % 3
        when 0 then store.write(create_token(index))
        when 1 then store.fetch
        when 2 then store.clear
        end
      end

      it 'handles writes, reads, and clears safely' do
        threads = Array.new(20) { |i| Thread.new { perform_operation(i) } }
        run_threads(threads)

        expect { store.fetch }.not_to raise_error
      end
    end
  end

  describe 'integration with TokenStore::Token' do
    let(:expires_at) { Time.now + 3600 }
    let(:complete_token) do
      ZaiPayment::Auth::TokenStore::Token.new(
        value: 'complete_token',
        expires_at: expires_at,
        type: 'Bearer'
      )
    end

    it 'stores and retrieves all Token attributes' do
      store.write(complete_token)
      retrieved = store.fetch

      expect(retrieved.value).to eq('complete_token')
      expect(retrieved.expires_at).to eq(expires_at)
      expect(retrieved.type).to eq('Bearer')
    end

    it 'stores tokens with minimal attributes' do
      token = ZaiPayment::Auth::TokenStore::Token.new(value: 'minimal_token')
      store.write(token)
      retrieved = store.fetch

      expect(retrieved.value).to eq('minimal_token')
    end

    it 'stores nil to clear the token' do
      store.write(complete_token)
      store.write(nil)

      expect(store.fetch).to be_nil
    end
  end
end
