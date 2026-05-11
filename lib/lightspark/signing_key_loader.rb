# frozen_string_literal: true

module Lightspark
  RECOVER_NODE_SIGNING_KEY_QUERY = <<-'GRAPHQL'
query RecoverNodeSigningKey(
    $node_id: ID!
) {
    entity(id: $node_id) {
        ... on LightsparkNodeWithOSK {
            encrypted_signing_private_key {
                encrypted_value
                cipher
            }
        }
    }
}
  GRAPHQL

  class SigningKeyLoader
    def self.from_node_id_and_password(node_id, password)
      new(node_id: node_id, password: password)
    end

    def initialize(node_id:, password:)
      @node_id = node_id
      @password = password
      @cached_signing_key = nil
    end

    def load_signing_key(client)
      return @cached_signing_key if @cached_signing_key

      response = client.execute(
        RECOVER_NODE_SIGNING_KEY_QUERY,
        operation_name: "RecoverNodeSigningKey",
        variables: { "node_id" => @node_id }
      )

      if response["errors"]
        raise Error, response["errors"].first["message"]
      end

      entity = response.dig("data", "entity")
      raise Error, "node not found: #{@node_id}" unless entity

      encrypted = entity["encrypted_signing_private_key"]
      raise Error, "node #{@node_id} has no encrypted_signing_private_key" unless encrypted

      key_bytes = Crypto.decrypt_private_key(
        encrypted["cipher"],
        encrypted["encrypted_value"],
        @password
      )
      @cached_signing_key = RsaSigningKey.new(key_bytes)
    end
  end
end
