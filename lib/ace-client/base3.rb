require 'openssl'
require 'cgi'
require 'nokogiri'
require 'time'

module AceClient
  class Base3 < Base
    attr_accessor :signature_method # TODO: HMAC-SHA256 or HMAC-SHA1
    attr_accessor :sampler

    format :xml

    def initialize(options={})
      super(options)
      @signature_method = options[:signature_method] || 'HmacSHA256'
      @authorization_key = options[:authorization_key] || 'authorization'
      @date_key = options[:date_key] || 'x-date'
      @nonce_key = options[:nonce_key] || 'x-amz-nonce'
      @authorization_prefix = options[:authorization_prefix] || 'AWS3-HTTPS'
      @nonce = options[:nonce]

      @sampler = options[:sampler]
      @before_signature = options[:before_signature]
      @before_request = options[:before_request]
    end

    def create_signature
      digest = OpenSSL::Digest::Digest.new(@signature_method.downcase.gsub(/hmac/, ''))
      Base64.encode64(OpenSSL::HMAC.digest(digest, secret_access_key, string_to_sign)).strip
    end

    def string_to_sign
      @nonce ? date + @nonce : date
    end
    
    def date
      @date ||= Time.now.utc.rfc822.gsub(/[\-\+]\d{4}$/, 'GMT')
    end
  end
end
