# frozen_string_literal: true

require_relative "lightspark/version"
require "net/http"
require "json"
require "time"

require_relative "lightspark/config"

module Lightspark
  class Error < StandardError; end
end

require "base64"
require "securerandom"

require_relative "lightspark/crypto"
require_relative "lightspark/signing_key"
require_relative "lightspark/signing_key_loader"
require_relative "lightspark/currency_amount"

module Lightspark

  CURRENT_ACCOUNT_QUERY = <<-'GRAPHQL'
query GetCurrentAccount {
  current_account {
    ...AccountFragment
  }
}

fragment AccountFragment on Account {
  __typename
  account_id: id
  account_created_at: created_at
  account_updated_at: updated_at
  account_name: name
}
  GRAPHQL

  FUND_NODE_MUTATION = <<-'GRAPHQL' + CURRENCY_AMOUNT_FRAGMENT
mutation FundNode(
    $node_id: ID!,
    $amount_sats: Long
) {
    fund_node(input: { node_id: $node_id, amount_sats: $amount_sats }) {
        amount {
            ...CurrencyAmountFragment
        }
    }
}

  GRAPHQL

  class Account
    attr_reader :account_id, :account_name,
      :account_created_at, :account_updated_at

    def initialize(options = {})
      @account_id = options[:account_id]
      @account_name = options[:account_name]
      @account_created_at = DateTime.parse options[:account_created_at]
      @account_updated_at = DateTime.parse options[:account_updated_at]
    end
  end

  class GraphqlClient
    attr_reader :uri

    def initialize
      @uri = URI.parse(api_base_uri)
      @node_keys = {}
    end

    def load_node_signing_key(node_id, loader)
      @node_keys[node_id] = loader.load_signing_key(self)
    end

    def node_signing_key(node_id)
      @node_keys[node_id]
    end

    def fund_node(node_id, amount_sats)
      signing_key = @node_keys[node_id]
      raise Error, "no signing key loaded for node #{node_id}; call load_node_signing_key first" unless signing_key

      response = execute(
        FUND_NODE_MUTATION,
        operation_name: "FundNode",
        variables: { "node_id" => node_id, "amount_sats" => amount_sats },
        signing_key: signing_key
      )

      raise Error, response["errors"].first["message"] if response["errors"]

      amount = response.dig("data", "fund_node", "amount")
      raise Error, "fund_node returned no amount" unless amount

      CurrencyAmount.from_json(amount)
    end

    def execute(query_string, operation_name: nil, variables: {}, context: {}, signing_key: nil)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(api_client_id, api_token)

      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request["X-GraphQL-Operation"] = operation_name if operation_name

      body = {}
      body["operationName"] = operation_name if operation_name
      body["query"] = query_string
      body["variables"] = variables if variables.any?

      if signing_key
        body["nonce"] = SecureRandom.random_number(0x7FFFFFFFFFFFFFFF)
        body["expires_at"] = (Time.now.utc + 3600).strftime("%Y-%m-%dT%H:%M:%SZ")
      end

      encoded = JSON.generate(body)
      request.body = encoded

      if signing_key
        signature = signing_key.sign(encoded)
        request["X-Lightspark-Signing"] = JSON.generate(
          "v" => 1,
          "signature" => Base64.strict_encode64(signature)
        )
      end

      response = connection.request(request)

      case response
      when Net::HTTPOK, Net::HTTPBadRequest
        JSON.parse(response.body)
      else
        { "errors" => [{ "message" => "#{response.code} #{response.message}" }] }
      end
    end

    # Returns a Net::HTTP object
    def connection
      Net::HTTP.new(uri.host, uri.port).tap do |client|
        client.use_ssl = uri.scheme == "https"
      end
    end

    def current_account
      parsed = execute(CURRENT_ACCOUNT_QUERY)
      if parsed["errors"]
      else
        Account.new symbolize_keys(parsed["data"]["current_account"])
      end
    end

    private

    def api_client_id
      Lightspark.configuration.client_id
    end

    def api_token
      Lightspark.configuration.client_secret
    end

    def api_base_uri
      "https://api.lightspark.com/graphql/server/2023-09-13"
    end

    def symbolize_keys(hash)
      {}.tap do |new_hash|
        hash.each_key { |key| new_hash[key.to_sym] = hash[key] }
      end
    end
  end
end
