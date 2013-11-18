# ACE (Amazon Compatible Environment) Client

## Synopsis

Simple ACE (Amazon Compatible Environment) client for debugging and testing.
On ACE, see [Transcend Computing | Amazon Compatible Environment](http://www.transcendcomputing.com/features/amazon-compatible-environment/).

## Background

On the view of API testing, AWS SDK is too complicated and not easy to fall back to lower levels like creating signature and sending requests.
Also, it validates parameters on the client side, and we can not test server-side validation.
ace-client solves this problem, and provide simple interface to test ACE environments.

## Usage

### Good Old Query + Sig2 Client

    require 'ace-client'

    rdb = AceClient::Query2.new(
      :endpoint => 'rds.ap-northeast-1.amazonaws.com',
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    )
    res = rdb.action('DescribeDBEngineVersions')
    p res['DescribeDBEngineVersionsResponse']['DescribeDBEngineVersionsResult']['DBEngineVersions']['DBEngineVersion'].first
    # => {"DBParameterGroupFamily"=>"mysql5.1", "Engine"=>"mysql", "DBEngineDescription"=>"MySQL Community Edition", "EngineVersion"=>"5.1.50", "DBEngineVersionDescription"=>"MySQL 5.1.50"}

## Copyright
