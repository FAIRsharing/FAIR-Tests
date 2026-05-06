ENV['RACK_ENV'] = 'test'

require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/config/'
end

require 'minitest/autorun'
require 'rack/test'
require 'json/ld'
require_relative '../fair_tests'


module TestHelper
  include Rack::Test::Methods

  def app
    FairTests
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
  def datacite_headers
    {
      'Accept'=>'application/vnd.citationstyles.csl+json'
    }
  end

  def parsed_response_body(body)
    body = JSON.parse(body)
    body.is_a?(String) ? JSON.parse(body) : body
  end

end

module JSON
  module LD
    class API
      def self.serializer(object, *_args, **options)
        ::JSON.generate(object, options.fetch(:serializer_opts, JSON_STATE))
      end
    end
  end
end
