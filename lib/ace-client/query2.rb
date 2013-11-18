require 'openssl'
require 'cgi'

module AceClient
  class Query2 < Base
    attr_accessor :http_method
    attr_accessor :signature_method # TODO: HMAC-SHA256 or HMAC-SHA1

    format :xml
    #debug_output $stderr

    def initialize(options={})
      super(options)
      @signature_method = options[:signature_method] || 'HmacSHA256'
    end

    def action(action, params={})
      params.update('Action' => action)
      execute(params)
    end

    def execute(params={})
      @params = params
      @params.update(
        'SignatureVersion' => '2',
        'SignatureMethod' => @signature_method,
        'AWSAccessKeyId' => @access_key_id,
        'Timestamp' => Time.now.getutc.iso8601.sub(/Z/, sprintf(".%03dZ",(Time.now.getutc.usec/1000)))
      )
      @params['Version'] = @version if @version
      @params['Signature'] = create_signature

      response = record_response do
        response = self.class.send(
           http_method,
           endpoint_url,
          :headers => {'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8', 'User-Agent' => 'ace-client v0.0.1'},
          :query => @params
        )
      end
      response
    end

    def endpoint_url
      protocol = use_ssl ? 'https' : 'http' 
      protocol + '://' + endpoint
    end

    def create_signature
      digest = OpenSSL::Digest::Digest.new(@signature_method.downcase.gsub(/hmac/, ''))
      Base64.encode64(OpenSSL::HMAC.digest(digest, secret_access_key, string_to_sign)).strip
    end

    def string_to_sign
      [@http_method.to_s.upcase, @endpoint, @path, canonical_query_string].join("\n")
    end

    def canonical_query_string
      @params.sort.collect { |param|
        "#{CGI::escape(param[0])}=#{CGI::escape(param[1])}"
      }.join("&").gsub('+', '%20').gsub('%7E', '~')
    end
  end
end
