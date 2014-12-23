module AceClient
  class Base4 < Base
    attr_accessor :headers
    attr_accessor :region
    attr_accessor :body
    attr_accessor :service
    attr_accessor :datetime

    def initialize(options)
      super(options)
      @service = options[:service]
      @region = options[:region]
    end

    def action(action, params={})
      params.update('Action' => action)
      execute(params)
    end

    def execute(params)
      @datetime = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      if http_method == :get
        execute_get(params)
      else http_method == :post
        execute_post(params)
      end
    end

    def execute_get(params)
      @headers = {}
      @headers['host'] = @endpoint

      @params = params
      @params['Version'] = @version if @version
      @params.update(
        'X-Amz-Algorithm' => 'AWS4-HMAC-SHA256',
        'X-Amz-Credential' => access_key_id + '/' + credential_string(datetime),
        'X-Amz-Date' => datetime,
        'X-Amz-SignedHeaders' => signed_headers
      )
      options = self.class.default_options.dup
      options[:query] = @params
      request = HTTParty::Request.new(Net::HTTP::Get, endpoint_url + @path, options)
      @query = request.send(:normalize_query, options[:query])

      @params.update('X-Amz-Signature' => signature(datetime))

      @body = ''

      request = HTTParty::Request.new(Net::HTTP::Get, endpoint_url + @path, options)
      request.perform
    end

    def execute_post(params)
      @params = params
      options = {}
      options = self.class.default_options.dup
      options[:body] = @params
      request = HTTParty::Request.new(Net::HTTP::Post, endpoint_url + @path, options)
      @body = request.send(:normalize_query, options[:body])

      @headers = {}
      add_authorization!
      options[:headers] = headers

      request = HTTParty::Request.new(Net::HTTP::Post, endpoint_url + @path, options)
      request.perform
    end

    def querystring
      if http_method == :post
        ''
      elsif http_method == :get
        @params.sort.collect { |param|
          "#{CGI::escape(param[0])}=#{CGI::escape(param[1])}"
        }.join("&").gsub('+', '%20').gsub('%7E', '~')
      end
    end

    def add_authorization!
      headers['content-type'] ||= 'application/x-www-form-urlencoded'
      headers['host'] = endpoint
      headers['x-amz-date'] = datetime
      #headers['x-amz-security-token'] = credentials.session_token if credentials.session_token
      headers['x-amz-content-sha256'] ||= hexdigest(body || '')
      headers['authorization'] = authorization(datetime)
    end

    protected

    def authorization datetime
      parts = []
      parts << "AWS4-HMAC-SHA256 Credential=#{access_key_id}/#{credential_string(datetime)}"
      parts << "SignedHeaders=#{signed_headers}"
      parts << "Signature=#{signature(datetime)}"
      parts.join(', ')
    end

    def signature datetime
      k_secret = secret_access_key
      k_date = hmac("AWS4" + k_secret, datetime[0,8])
      k_region = hmac(k_date, region)
      k_service = hmac(k_region, service)
      k_credentials = hmac(k_service, 'aws4_request')
      hexhmac(k_credentials, string_to_sign(datetime))
    end

    def string_to_sign datetime
      parts = []
      parts << 'AWS4-HMAC-SHA256'
      parts << datetime
      parts << credential_string(datetime)
      parts << hexdigest(canonical_request)
      parts.join("\n")
    end

    def credential_string datetime
      parts = []
      parts << datetime[0,8]
      parts << region
      parts << service
      parts << 'aws4_request'
      parts.join("/")
    end

    def canonical_request
      parts = []
      parts << http_method.to_s.upcase
      parts << @path
      parts << querystring
      parts << canonical_headers + "\n"
      parts << signed_headers
      if http_method == :post
        parts << headers['x-amz-content-sha256']
      else
        parts << hexdigest('')
      end
      parts.join("\n")
    end

    def signed_headers
      to_sign = headers.keys.map{|k| k.to_s.downcase }
      to_sign.delete('authorization')
      to_sign.sort.join(";")
    end

    def canonical_headers
      headers = []
      self.headers.each_pair do |k,v|
        headers << [k,v] unless k == 'authorization'
      end
      headers = headers.sort_by(&:first)
      headers.map{|k,v| "#{k}:#{canonical_header_values(v)}" }.join("\n")
    end

    def canonical_header_values values
      values = [values] unless values.is_a?(Array)
      values.map(&:to_s).join(',').gsub(/\s+/, ' ').strip
    end

    def hexdigest value
      digest = Digest::SHA256.new
      if value.respond_to?(:read)
        chunk = nil
        chunk_size = 1024 * 1024 # 1 megabyte
        digest.update(chunk) while chunk = value.read(chunk_size)
        value.rewind
      else
        digest.update(value)
      end
      digest.hexdigest
    end

    def hmac key, value
      OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, value)
    end

    def hexhmac key, value
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha256'), key, value)
    end
  end
end

