require 'openssl'
require 'cgi'
require 'nokogiri'

module AceClient
  class Query2 < Base
    attr_accessor :http_method
    attr_accessor :signature_method # TODO: HMAC-SHA256 or HMAC-SHA1
    attr_accessor :sampler

    format :xml
    #debug_output $stderr

    def initialize(options={})
      super(options)
      @signature_method = options[:signature_method] || 'HmacSHA256'
      @sampler = options[:sampler]
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
      @params.update(
        'SignatureVersion' => '2',
        'SignatureMethod' => @signature_method,
        'AWSAccessKeyId' => @access_key_id,
        'Timestamp' => Time.now.getutc.iso8601.sub(/Z/, sprintf(".%03dZ",(Time.now.getutc.usec/1000)))
      )
      @params['Version'] = @version if @version
      @params['Signature'] = create_signature

      options = {
        :headers => {
          'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8'
        },
        :query => @params
      }
      options[:headers]['User-Agent'] = @user_agent if @user_agent

      if http_method == :get
        http_method_class = Net::HTTP::Get
      elsif http_method == :post
        http_method_class = Net::HTTP::Post
      end

      request = HTTParty::Request.new(http_method_class, endpoint_url + @path, options)
      if dryrun
        request
      else
        sample_request(request) if @sampler
        response = record_response { request.perform }
        sample_response(response) if @sampler
        response
      end
    end

    def sample_request(request)
      query = request.options[:query].dup
      variable_keys = %w(Version SignatureVersion SignatureMethod Timestamp AWSAccessKeyId Signature)
      variables = {}
      variable_keys.each do |key|
        variables[key] = query.delete(key)
      end
      action = query.delete('Action')
      @sampler[:output].puts "# #{action}"
      @sampler[:output].puts "## request"
      @sampler[:output].puts "#{request.path.to_s}"
      @sampler[:output].puts "    ?Action=#{action}"
      query.each do |key, value|
        @sampler[:output].puts "    &#{key}=#{CGI.escape(value)}"
      end
      variable_keys.each do |key|
        if variables[key]
          value = @sampler[:echo][key] || CGI.escape(variables[key])
          @sampler[:output].puts "    &#{key}=#{value}"
        end
      end
    end

    def sample_response(response)
      @sampler[:output].puts "## response"
      @sampler[:output].puts Nokogiri::XML(response.body).to_xml(:indent => 4)
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
