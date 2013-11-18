require 'httparty'
require 'uri'

module AceClient
  class Base
    include HTTParty

    attr_accessor :access_key_id
    attr_accessor :secret_access_key
    attr_accessor :endpoint
    attr_accessor :http_proxy
    attr_accessor :http_method
    attr_accessor :use_ssl
    attr_accessor :last_response_time

    def initialize(options)
      @access_key_id = options[:access_key_id]
      @secret_access_key = options[:secret_access_key]
      @endpoint = options[:endpoint]
      @http_proxy = options[:http_proxy]
      @http_method = options[:http_method] || :post
      @use_ssl = options[:use_ssl] || true
      @version = options[:version]
      @path = options[:path] || '/'
      set_http_proxy
    end

    def set_http_proxy
      if @http_proxy
        uri = URI.parse(@http_proxy)
        self.class.http_proxy(uri.scheme + '://' + uri.host, uri.port)
      end
    end

    def record_response
      start_time = Time.now
      @last_response = yield
      @last_response_time = Time.now - start_time
      @last_response
    end
  end
end
