# frozen_string_literal: true

require_relative "lightspark/version"
require "net/http"
require "json"
require "time"

module Lightspark
  class Error < StandardError; end

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
    end

    def execute(query_string, operation_name: nil, variables: {}, context: {})
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(api_client_id, api_token)

      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"

      body = {}
      body["query"] = query_string
      body["variables"] = variables if variables.any?
      body["operationName"] = operation_name if operation_name
      request.body = JSON.generate(body)

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
      ENV["LIGHTSPARK_API_TOKEN_CLIENT_ID"]
    end

    def api_token
      ENV["LIGHTSPARK_API_TOKEN_CLIENT_SECRET"]
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
