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

## Installation

    gem install ace-client

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

### Rewrite Parameters before Creating Signature

You can rewrite default parameters with `:before_signature` hook before creating signature.
For example, you have to specify `AccessKeyId` instead of `AWSAccessKeyId` when using NIFTY Cloud API (http://cloud.nifty.com/api/rest/authenticate.htm).
You can intercept params and rewrite `AWSAccessKeyId` to `AccessKeyId` using `:before_signature`.

    require 'ace-client'
    
    compute = AceClient::Query2.new(
      :endpoint => 'cp.cloud.nifty.com',
      :path => '/api',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
      :before_signature => lambda {|params|
        params['AccessKeyId'] = params.delete('AWSAccessKeyId')
      }
    )
    p compute.action('DescribeRegions')
    # => #<HTTParty::Response:0x7c0b0a0 parsed_response={"DescribeRegionsResponse"=>{"requestId"=>"df9de22f-cb3b-4cf9-9ee0-377e78742bf4", "regionInfo"=>{"item"=>[{"regionName"=>"east-1", "regionEndpoint"=>"east-1.cp.cloud.nifty.com", "messageSet"=>{"item"=>nil}, "isDefault"=>"true"}, {"regionName"=>"west-1", "regionEndpoint"=>"west-1.cp.cloud.nifty.com", "messageSet"=>{"item"=>nil}, "isDefault"=>"false"}]}}}, @response=#<Net::HTTPOK 200 OK readbody=true>, @headers={"date"=>["Sat, 23 Nov 2013 05:03:20 GMT"], "x-frame-options"=>["SAMEORIGIN"], "content-type"=>["text/xml;charset=utf-8"], "content-length"=>["558"], "vary"=>["Accept-Encoding"], "connection"=>["close"]}>

### Command Line Support

Above version 0.0.6, ace-client comes with command line program `ace-q2`.
Environment variable ACE_ENDPOINT, ACE_ACCESS_KEY, ACE_SECRET_ACCESS_KEY should be defined for `ace-q2` to work.

    $ export ACE_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
    $ export ACE_SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
    $ export ACE_ENDPOINT=rds.ap-northeast-1.amazonaws.com
    $ ace-q2 DescribeDBSecurityGroups | head
    <?xml version="1.0"?>
    <DescribeDBSecurityGroupsResponse xmlns="http://rds.amazonaws.com/admin/2009-10-16/">
      <DescribeDBSecurityGroupsResult>
        <DBSecurityGroups>
          <DBSecurityGroup>
            <EC2SecurityGroups/>
            <DBSecurityGroupDescription>default</DBSecurityGroupDescription>
            <IPRanges>
              <IPRange>
                <CIDRIP>10.245.226.45/0</CIDRIP>
    $ export ACE_ENDPOINT=sqs.ap-northeast-1.amazonaws.com
    $ ace-q2 CreateQueue QueueName=tily001
    <?xml version="1.0"?>
    <CreateQueueResponse xmlns="http://queue.amazonaws.com/doc/2012-11-05/">
        <CreateQueueResult>
            <QueueUrl>https://sqs.ap-northeast-1.amazonaws.com/012345678910/tily001</QueueUrl>
        </CreateQueueResult>
        <ResponseMetadata>
            <RequestId>305442f3-a62c-552a-8a51-09fea623f39e</RequestId>
        </ResponseMetadata>
    </CreateQueueResponse>

## How to develop with docker

```
## Define your environment variables
$ vi .env


## Execute command-line tool with docker
$ docker-compose run --rm app ruby bin/ace-q2 
Usage: ace-q2 DescribeSomethings Key1=Value1 Key2=Value2 ...
```

## TODO

* query + sig4 support
* json + sig4 support
* logging
* handle redirects
* socket/connection timeout configuration
* rewrite query and header before/after genrating signature (maybe hook-like interface)
* environment variable suppoort (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, HTTP_PROXY)

## How to build & publish tily/ace-q2 docker image

```
$ docker build -t tily/ace-q2:0.0.23 -f Dockerfile.ace-q2 .
$ docker tag tily/ace-q2:0.0.23 tily-ace-q2:latest
$ docker push tily/ace-q2:0.0.23
$ docker push tily/ace-q2:latest
```

## Copyright
