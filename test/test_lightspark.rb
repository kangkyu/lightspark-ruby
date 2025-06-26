# frozen_string_literal: true

require "test_helper"

class TestLightspark < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Lightspark::VERSION
  end

  def test_uri_to_client_instances
    client = Lightspark::GraphqlClient.new

    # expected: "https://api.lightspark.com/graphql/server/2023-09-13"
    # actual: client.uri.to_s
    assert_equal "https://api.lightspark.com/graphql/server/2023-09-13", client.uri.to_s
  end

  def test_current_account
    client = Lightspark::GraphqlClient.new

    assert_instance_of String, client.current_account.account_id
  end
end
