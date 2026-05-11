# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

module Lightspark
  module Crypto
    KEY_LEN = 32
    GCM_TAG_LEN = 16
    AES_BLOCK_SIZE = 16

    module_function

    def decrypt_private_key(cipher_version, encrypted_value, password)
      decoded = Base64.strict_decode64(encrypted_value)

      if cipher_version == "AES_256_CBC_PBKDF2_5000_SHA256"
        header = { "v" => 0, "i" => 5000 }
        decoded = decoded.byteslice(8, decoded.bytesize - 8)
      else
        header = JSON.parse(cipher_version)
        header["v"] = 3 if header["lsv"] == 2
      end

      version = header["v"].to_i
      raise Error, "unknown version" if version < 0 || version > 4

      iteration = header["i"].to_i

      if version == 3
        salt = decoded.byteslice(decoded.bytesize - 8, 8)
        nonce = decoded.byteslice(0, 12)
        ciphertext = decoded.byteslice(12, decoded.bytesize - 12 - 8)
        key = derive_key(password, salt, iteration, KEY_LEN)
        return decrypt_gcm(ciphertext, key, nonce)
      end

      if version < 4
        salt_len = 8
        iv_len = 16
      else
        salt_len = 16
        iv_len = 12
      end

      salt = decoded.byteslice(0, salt_len)
      ciphertext = decoded.byteslice(salt_len, decoded.bytesize - salt_len)
      derived = derive_key(password, salt, iteration, KEY_LEN + iv_len)
      key = derived.byteslice(0, KEY_LEN)
      iv = derived.byteslice(KEY_LEN, iv_len)

      if version < 2
        decrypt_cbc(ciphertext, key, iv)
      else
        decrypt_gcm(ciphertext, key, iv)
      end
    end

    def derive_key(password, salt, iterations, length)
      OpenSSL::KDF.pbkdf2_hmac(
        password,
        salt: salt,
        iterations: iterations,
        length: length,
        hash: "SHA256"
      )
    end

    def decrypt_gcm(ciphertext, key, nonce)
      tag = ciphertext.byteslice(ciphertext.bytesize - GCM_TAG_LEN, GCM_TAG_LEN)
      data = ciphertext.byteslice(0, ciphertext.bytesize - GCM_TAG_LEN)
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      cipher.key = key
      cipher.iv = nonce
      cipher.auth_tag = tag
      cipher.auth_data = ""
      cipher.update(data) + cipher.final
    end

    # Mirrors go-sdk/crypto/crypto.go decryptCbc: drops the first AES block of
    # the ciphertext before decrypting, then strips PKCS7 padding manually.
    def decrypt_cbc(ciphertext, key, iv)
      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.padding = 0
      data = ciphertext.byteslice(AES_BLOCK_SIZE, ciphertext.bytesize - AES_BLOCK_SIZE)
      decrypted = cipher.update(data) + cipher.final
      pkcs7_unpad(decrypted)
    end

    def pkcs7_unpad(data)
      raise Error, "cannot unpad empty data" if data.empty?

      pad = data.bytes.last
      raise Error, "invalid padding length" if pad <= 0 || pad > data.bytesize

      tail = data.byteslice(data.bytesize - pad, pad)
      raise Error, "invalid padding" unless tail.bytes.all? { |b| b == pad }

      data.byteslice(0, data.bytesize - pad)
    end
  end
end
