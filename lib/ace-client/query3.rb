require 'openssl'
require 'cgi'
require 'nokogiri'
require 'time'

module AceClient
  class Query3 < Base
    attr_accessor :http_method
    attr_accessor :signature_method # TODO: HMAC-SHA256 or HMAC-SHA1
    attr_accessor :sampler

    format :xml

    def initialize(options={})
      super(options)
      @signature_method = options[:signature_method] || 'HmacSHA256'
      @authorization_key = options[:authorization_key] || 'authorization'
      @date_key = options[:date_key] || 'x-date'
      @authorization_prefix = options[:authorization_prefix] || 'AWS3-HTTPS'
      @nonce = options[:nonce]

      @sampler = options[:sampler]
      @before_signature = options[:before_signature]
      @before_request = options[:before_request]
    end

    def action(action, params={})
      params.update('Action' => action)
      execute(params)
    end

    def dryrun(action, params={})
      params.update('Action' => action)
      execute(params, true)
    end

    def execute(params={}, dryrun=false)
      @params = params
      @params['Version'] = @version if @version

      @before_signature.call(@params) if @before_signature

      signature = create_signature

      options = self.class.default_options.dup
      options[:headers] = {}
      options[:headers]['Date'] = date
      #options[:headers]['X-Nifty-Authorization'] = "NIFTY3-HTTPS NiftyAccessKeyId=#{access_key_id},Algorithm=#{signature_method},Signature=#{signature}"
      options[:headers]['X-Amzn-Authorization'] = "AWS3-HTTPS AWSAccessKeyId=#{access_key_id},Algorithm=#{signature_method},Signature=#{signature}"
      options[:headers]['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
      options[:headers]['User-Agent'] = @user_agent if @user_agent

      if http_method == :get
        options[:query] = @params
        http_method_class = Net::HTTP::Get
      elsif http_method == :post
        options[:body] = @params
        http_method_class = Net::HTTP::Post
      end

      @before_request.call(@params) if @before_request

      request = HTTParty::Request.new(http_method_class, endpoint_url + @path, options)
      if dryrun
        request
      else
        record_response { request.perform }
      end
    end

    def create_signature
      digest = OpenSSL::Digest::Digest.new(@signature_method.downcase.gsub(/hmac/, ''))
      Base64.encode64(OpenSSL::HMAC.digest(digest, secret_access_key, string_to_sign)).strip
    end

    def string_to_sign
      date
    end
    
    def date
      @date ||= Time.now.utc.rfc822.gsub(/[\-\+]\d{4}$/, 'GMT')
    end
  end
end
