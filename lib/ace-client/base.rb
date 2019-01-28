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
    attr_accessor :last_response
    attr_accessor :last_response_time
    attr_accessor :user_agent

    def initialize(options)
      @access_key_id = options[:access_key_id] || ENV['ACE_ACCESS_KEY_ID']
      @secret_access_key = options[:secret_access_key] || ENV['ACE_SECRET_ACCESS_KEY']
      @endpoint = options[:endpoint] || ENV['ACE_ENDPOINT']
      @http_proxy = options[:http_proxy] || ENV['HTTP_PROXY']
      @http_method = options[:http_method] || :post
      @access_key_id_key = options[:access_key_id_key] || ENV['ACE_ACCESS_KEY_ID_KEY'] || 'AWSAccessKeyId'
      @host = options[:host]
      if @timeout = options[:timeout] || ENV['ACE_TIMEOUT']
        self.class.default_timeout @timeout
      end
      if options.key?(:use_ssl)
        @use_ssl = options[:use_ssl]
      elsif ENV['ACE_USE_SSL']
        if ENV['ACE_USE_SSL'] == 'false'
          @use_ssl = false
        else
          @use_ssl = true
        end
      else
        @use_ssl = true
      end
      if options.key?(:host_with_port)
        @host_with_port = options[:host_with_port]
      elsif ENV['ACE_HOST_WITH_PORT']
        if ENV['ACE_HOST_WITH_PORT'] == 'false'
          @host_with_port = false
        else
          @host_with_port = true
        end
      else
        @host_with_port = false
      end
      if options[:debug_output]
        self.class.debug_output(options[:debug_output])
      elsif %w(STDOUT STDERR).include?(ENV['ACE_DEBUG_OUTPUT'])
        if ENV['ACE_DEBUG_OUTPUT'] == 'STDOUT'
          self.class.debug_output($stdout)
        else
          self.class.debug_output($stderr)
        end
      end
      self.class.format (options[:response_format] || ENV['ACE_RESPONSE_FORMAT'] || self.class.format).to_sym
      @version = options[:version]
      @path = options[:path] || ENV['ACE_PATH'] || '/'
      @user_agent = options[:user_agent]
      @headers = options[:headers] || {}
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
