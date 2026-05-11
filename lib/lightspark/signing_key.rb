# frozen_string_literal: true

require "openssl"

module Lightspark
  class SigningKey
    def sign(_payload)
      raise NotImplementedError
    end
  end

  class RsaSigningKey < SigningKey
    attr_reader :private_key_bytes

    def initialize(private_key_bytes)
      @private_key_bytes = private_key_bytes
    end

    # Mirrors go-sdk requester.RsaSigningKey.Sign: parses the PKCS8 DER private
    # key and signs with RSA-PSS over SHA-256, MGF1-SHA-256, max salt length.
    def sign(payload)
      pkey = OpenSSL::PKey.read(@private_key_bytes)
      raise Error, "private key is not an RSA key" unless pkey.is_a?(OpenSSL::PKey::RSA)

      pkey.sign_pss("SHA256", payload, salt_length: :max, mgf1_hash: "SHA256")
    end
  end
end
