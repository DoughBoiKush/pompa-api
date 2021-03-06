require 'securerandom'
require 'digest'
require 'base64'
require 'zlib'
require 'openssl'

module Pompa
  class Utils
    class << self
      DEFAULT_TRUNCATE = 50
      CIPHER = 'chacha20'.freeze

      def random_code
        SecureRandom.urlsafe_base64(code_length)
      end

      def urlsafe_digest(value)
        sha1 = Digest::SHA1.new
        sha1 << value
        Base64.urlsafe_encode64(sha1.digest).gsub('=', '')[0, code_length]
      end

      def code_length
        @code_length ||= Rails.configuration.pompa.code_length
      end

      def liquid_flags
        { strict_variables: true, strict_filters: true }
      end

      def truncate(value)
        if value.is_a?(Hash)
          value.transform_values { |x| truncate(x) }
        elsif value.is_a?(Array)
          value.map { |x| truncate(x) }
        elsif value.is_a?(String)
          value.truncate(DEFAULT_TRUNCATE)
        else
          value
        end
      end

      def permit_raw(params, tap, param)
        if params[param].respond_to?(:to_unsafe_h)
          tap[param] = params[param].to_unsafe_h
        elsif params[param].respond_to?(:map)
          tap[param] = params[param].map { |p|
            p.to_unsafe_h if p.respond_to?(:to_unsafe_h)
          }
        elsif params[param].nil?
          tap[param] = nil
        else
          tap[param] = params[param]
        end
      end

      def sanitize_filename(filename)
        bad_chars = ['/', '\\', '?', '%', '*', ':', '|',
          '"', '<', '>']
        bad_chars.each do |bad_char|
          filename.gsub!(bad_char, '_')
        end
        filename
      end

      def encrypt(input, compress = false)
        input = Zlib::Deflate.new.deflate(input, Zlib::FINISH) if compress

        cipher = OpenSSL::Cipher.new(CIPHER)
        iv = cipher.random_iv

        cipher.encrypt
        cipher.iv = iv
        cipher.key = encryption_key

        encrypted = iv + cipher.update(input) + cipher.final
        Base64.urlsafe_encode64(encrypted).gsub('=', '')
      end

      def decrypt(input, decompress = false)
        decoded = Base64.decode64(input.tr('-_', '+/'))

        cipher = OpenSSL::Cipher.new(CIPHER)
        iv = decoded[0..cipher.iv_len - 1]
        encrypted = decoded[cipher.iv_len..-1]

        cipher.decrypt
        cipher.iv = iv
        cipher.key = encryption_key

        plaintext = cipher.update(encrypted) + cipher.final
        decompress ? Zlib::Inflate.new.inflate(plaintext) : plaintext
      end

      private
        def encryption_key
          return @encryption_key unless @encryption_key.nil?

          cipher = OpenSSL::Cipher.new(CIPHER)
          cipher.encrypt

          @encryption_key = Rails.application.key_generator.generate_key('',
            cipher.key_len)
        end
    end
  end
end
