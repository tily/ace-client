require 'openssl'
require 'cgi'
require 'nokogiri'
require 'time'

module AceClient
  class Query3 < Base3
    attr_accessor :http_method

    format :xml

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
      options[:headers][@authorization_key] = "#{@authorization_prefix} #{@access_key_id_key}=#{access_key_id},Algorithm=#{signature_method},Signature=#{signature}"
      options[:headers]['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
      options[:headers]['User-Agent'] = @user_agent if @user_agent
      options[:headers][@nonce_key] = @nonce if @nonce

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
  end
end
