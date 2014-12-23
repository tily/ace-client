require 'openssl'
require 'cgi'
require 'nokogiri'
require 'time'
require 'builder'

module AceClient
  class Xml3 < Base3
    format :xml

    def action(method, path, params={})
      record_response do
        create_request(method, path, params).perform
      end
    end

    def dryrun(method, path, params={})
      create_request(method, path, params)
    end

    def create_request(method, path, params={})
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

      http_method_class = case method
        when :get; Net::HTTP::Get
        when :post; Net::HTTP::Post
        when :delete; Net::HTTP::Delete
      end

      if !params.empty?
        builder = Builder::XmlMarkup.new
        options[:body] = builder.tag!(params.keys.first) do |b|
		params[params.keys.first].each do |k, v|
			b.tag!(k, v)
		end
	end
      end

      @path = File.join('/', @version, path)

      @before_request.call(@params) if @before_request

      HTTParty::Request.new(http_method_class, endpoint_url + @path, options)
    end
  end
end
