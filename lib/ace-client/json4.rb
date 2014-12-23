module AceClient
  class Json4 < Base4
    format :json

    def dryrun(action, params={})
      create_request(action, params)
    end

    def action(action, params={})
      create_request(action, params).perform
    end

    def create_request(action, params={})
      @datetime = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      @params = params
      options = self.class.default_options.dup
      @body = options[:body] = @params.to_json

      @headers = {}
      headers['x-amz-target'] = "Hoge_20141213.#{action}"
      add_authorization!
      options[:headers] = headers

      HTTParty::Request.new(Net::HTTP::Post, endpoint_url + @path, options)
    end
  end
end

