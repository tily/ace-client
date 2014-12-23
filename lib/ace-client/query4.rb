module AceClient
  class Query4 < Base4
    attr_accessor :query

    format :xml

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
  end
end

