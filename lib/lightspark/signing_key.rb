# frozen_string_literal: true

require "openssl"

module Lightspark
  class SigningKey
    def sign(_payload)
      raise NotImplementedError
    end
  end

  class RsaSigningKey < SigningKey
    def initialize(private_key_bytes)
      @pkey = OpenSSL::PKey.read(private_key_bytes)
      raise Error, "private key is not an RSA key" unless @pkey.is_a?(OpenSSL::PKey::RSA)
    end

    # Mirrors go-sdk requester.RsaSigningKey.Sign: RSA-PSS over SHA-256,
    # MGF1-SHA-256, max salt length.
    def sign(payload)
      @pkey.sign_pss("SHA256", payload, salt_length: :max, mgf1_hash: "SHA256")
    end
  end
end
