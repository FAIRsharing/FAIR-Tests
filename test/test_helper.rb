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

  CHAMPION_URL = "https://tools.ostrails.eu/champion/harvest_only"
  CHAMPION_HEADERS = {
    'Accept'=>'application/json',
    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Content-Type'=>'application/json',
    'User-Agent'=>'Ruby'
  }

  def stub_metadata_harvesting(response_body, resource_identifier: "https://example.org/records/abc123")
    body = response_body.is_a?(String) ? response_body : response_body.to_json

    stub_request(:post, CHAMPION_URL).
      with(
        body: { resource_identifier: resource_identifier }.to_json,
        headers: CHAMPION_HEADERS
      ).
      to_return(status: 200, body: body, headers: {})
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
