# ACE (Amazon Compatible Environment) Client

## Synopsis

Simple ACE (Amazon Compatible Environment) client for debugging and testing.
On ACE, see [Transcend Computing | Amazon Compatible Environment](http://www.transcendcomputing.com/features/amazon-compatible-environment/).

## Background

On the view of API testing, AWS SDK is too complicated and not easy to fall back to lower levels like creating signature and sending requests.
Also, it validates parameters on the client side, and we can not test server-side validation.
ace-client solves this problem, and provide simple interface to test ACE environments.

## Features

* no client-side validation
* no dynamic API exception (both success and error response is returned as raw response)

## Usage

### Good Old Query + Sig2 Client

RDS:

    require 'ace-client'

    rds = AceClient::Query2.new(
      :endpoint => 'rds.ap-northeast-1.amazonaws.com',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    )
    res = rds.action('DescribeDBEngineVersions', 'MaxRecords' => '20')
    p res['DescribeDBEngineVersionsResponse']['DescribeDBEngineVersionsResult']['DBEngineVersions']['DBEngineVersion'].first
    # => {"DBParameterGroupFamily"=>"mysql5.1", "Engine"=>"mysql", "DBEngineDescription"=>"MySQL Community Edition", "EngineVersion"=>"5.1.50", "DBEngineVersionDescription"=>"MySQL 5.1.50"}

SQS:

    require 'ace-client'
    
    sqs = AceClient::Query2.new(
      :endpoint => 'sqs.ap-northeast-1.amazonaws.com',
      :version => '2012-11-05',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    )
    p sqs.action('CreateQueue', 'QueueName' => 'queue001')
    # => #<HTTParty::Response:0x163e5308 parsed_response={"CreateQueueResponse"=>{"CreateQueueResult"=>{"QueueUrl"=>"https://sqs.ap-northeast-1.amazonaws.com/370162190418/queue001"}, "ResponseMetadata"=>{"RequestId"=>"66640219-a36d-54d8-8c56-491a1f19fa2c"}}}, @response=#<Net::HTTPOK 200 OK readbody=true>, @headers={"server"=>["Server"], "date"=>["Mon, 18 Nov 2013 06:56:52 GMT"], "content-type"=>["text/xml"], "content-length"=>["333"], "connection"=>["close"], "x-amzn-requestid"=>["66640219-a36d-54d8-8c56-491a1f19fa2c"]}>

### Query + Sig4 Client

(coming soon)

### JSON + Sig4 Client

(coming soon)

### Setting HTTP Proxy

Construct your client with :http_proxy option (Proxy user and password is not currently supported.)

    sqs = AceClient::Query2.new(
      :endpoint => 'sqs.ap-northeast-1.amazonaws.com',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
      :http_proxy => 'http://example.com:8080'
    )
    p rdb.action('ListQueues')

### GET/POST Support

you can specify your http method with :http_method option (Default is :post).

    sqs = AceClient::Query2.new(
      :http_method => :get,
      :endpoint => 'sqs.ap-northeast-1.amazonaws.com',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
      :http_proxy => 'http://example.com:8080'
    )
    p sqs.action('ListQueues')

### Getting Last Response Info

    sqs = AceClient::Query2.new(
      :endpoint => 'sqs.ap-northeast-1.amazonaws.com',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    )
    p sqs.action('ListQueues')
    p sqs.last_response      # currently HTTParty::Response object
    p sqs.last_response_time # returned in seconds (Float object)

### Dry-Run Mode

If you want to get request information rather than sending actual request, use `dryrun` instead of `action`.
`dryrun` returns HTTParty::Request object that would have been performed if you have used `action`.
On HTTParty::Request class, see HTTParty's document.

    sqs = AceClient::Query2.new(
      :http_method => :get,
      :endpoint => 'sqs.ap-northeast-1.amazonaws.com',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    )
    req = sqs.dryrun('CreateQueue', 'QueueName' => 'queue001')
    puts req.uri.to_s
    # => https://sqs.ap-northeast-1.amazonaws.com/?QueueName=queue001&Action=CreateQueue&SignatureVersion=2&SignatureMethod=HmacSHA256&AWSAccessKeyId=XXXXXXXXXXXXXXXXXXXX&Timestamp=2013-11-19T08%3A53%3A40.115Z&Version=2012-11-05&Signature=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

### Setting User-Agent in HTTP Request Header

Specify `:user_agent` option in your constructor.

    AceClient::Query2.new(
      :endpoint => 'sqs.ap-northeast-1.amazonaws.com',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
      :user_agent => "ace-client v#{AceClient::VERSION}"
    )

### Output Sample Request/Response Log

Set :sampler option to output AWS-document-like logs.

If you write code like this:

    sqs = AceClient::Query2.new(
      :endpoint => 'sqs.ap-northeast-1.amazonaws.com',
      :version => '2012-11-05',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
      :sampler => {
        :output => STDOUT,
        :echo => {
          'AWSAccessKeyId' => '<AWS Access Key Id>',
          'Signature' => '<Signature>'
        }
      }
    )
    sqs.action('CreateQueue', 'QueueName' => 'queue001')

Then output would be:

    # CreateQueue
    ## request
    https://sqs.ap-northeast-1.amazonaws.com/
        ?Action=CreateQueue
        &QueueName=queue001
        &Version=2012-11-05
        &SignatureVersion=2
        &SignatureMethod=HmacSHA256
        &Timestamp=2013-11-19T10%3A51%3A46.110Z
        &AWSAccessKeyId=<AWS Access Key Id>
        &Signature=<Signature>
    ## response
    <?xml version="1.0"?>
    <CreateQueueResponse xmlns="http://queue.amazonaws.com/doc/2012-11-05/">
        <CreateQueueResult>
            <QueueUrl>https://sqs.ap-northeast-1.amazonaws.com/370162190418/queue001</QueueUrl>
        </CreateQueueResult>
        <ResponseMetadata>
            <RequestId>1406b1f3-c3e5-51ac-a291-faf686e77b1e</RequestId>
        </ResponseMetadata>
    </CreateQueueResponse>

## TODO

* query + sig4 support
* json + sig4 support
* logging
* handle redirects
* socket/connection timeout configuration
* rewrite query and header before/after genrating signature (maybe hook-like interface)
* environment variable suppoort (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, HTTP_PROXY)

## Copyright
