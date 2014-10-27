require 'httparty'
require 'uri'

module AceClient
  class Base
    include HTTParty
    ssl_version :TLSv1

    attr_accessor :access_key_id
    attr_accessor :secret_access_key
    attr_accessor :endpoint
    attr_accessor :http_proxy
    attr_accessor :http_method
    attr_accessor :use_ssl
    attr_accessor :last_response
    attr_accessor :last_response_time
    attr_accessor :user_agent

    def initialize(options)
      @access_key_id = options[:access_key_id] || ENV['ACE_ACCESS_KEY_ID']
      @secret_access_key = options[:secret_access_key] || ENV['ACE_SECRET_ACCESS_KEY']
      @endpoint = options[:endpoint] || ENV['ACE_ENDPOINT']
      @http_proxy = options[:http_proxy] || ENV['HTTP_PROXY']
      @http_method = options[:http_method] || :post
      @use_ssl = options[:use_ssl] || true
      @version = options[:version]
      @path = options[:path] || '/'
      @user_agent = options[:user_agent]
      set_http_proxy
    end

    def set_http_proxy
      if @http_proxy
        uri = URI.parse(@http_proxy)
        self.class.http_proxy(uri.host, uri.port)
      end
    end

    def record_response
      start_time = Time.now
      @last_response = yield
      @last_response_time = Time.now - start_time
      @last_response
    end

    def endpoint_url
      protocol = use_ssl ? 'https' : 'http' 
      protocol + '://' + endpoint
    end
  end
end
