ENV['RACK_ENV'] = 'test'
ENV['FAIRSHARING_CACHE_ENABLED'] = 'false'
ENV['ORA_CACHE_ENABLED'] = 'false'

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

  def setup
    super
    stub_default_fairsharing_identifier_requests
  end

  def app
    FairTests
  end

  def stub_default_fairsharing_identifier_requests
    doi_url = 'https://doi.org/10.25504%2FFAIRsharing.5678'
    fairsharing_url = 'https://fairsharing.org/FAIRsharing.5678'
    stub_request(:get, doi_url).
      to_return(status: 302, headers: { 'Location' => fairsharing_url })
    stub_request(:get, fairsharing_url).to_return(status: 200)

    stub_request(:post, ENV.fetch('FAIRSHARING_API_URL')).
      with do |request|
        JSON.parse(request.body)['query'].
          include?('fairsharingRecord(id: "https://example.org/not-a-fairsharing-record")')
      end.
      to_return(
        status: 200,
        body: { 'data' => { 'fairsharingRecord' => nil } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  CHAMPION_URL = "https://tools.ostrails.eu/champion/harvest_only"
  CHAMPION_HEADERS = {
    'Accept'=>'application/json',
    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Content-Type'=>'application/json',
    'User-Agent'=>'Ruby'
  }
  ORA_RESOURCE_IDENTIFIER = "https://ora.ox.ac.uk/objects/uuid:d7998de7-1c66-443b-9df7-b19dddd256b6"

  def stub_metadata_harvesting(response_body, resource_identifier: "https://example.org/records/abc123")
    body = response_body.is_a?(String) ? response_body : response_body.to_json

    stub_request(:post, CHAMPION_URL).
      with(
        body: { resource_identifier: resource_identifier }.to_json,
        headers: CHAMPION_HEADERS
      ).
      to_return(status: 200, body: body, headers: {})
  end

  def stub_request_jsonld(response_body, resource_identifier: ORA_RESOURCE_IDENTIFIER)
    body = response_body.is_a?(String) ? response_body : response_body.to_json

    stub_request(:get, resource_identifier).
      with(
        headers: {
          'Accept' => 'application/ld+json',
          'Content-Type' => 'application/ld+json'
        }
      ).
      to_return(status: 200, body: body, headers: {})
  end

  def stub_request_xml(response_body, resource_identifier: ORA_RESOURCE_IDENTIFIER)
    stub_request(:get, resource_identifier).
      with(
        headers: {
          'Accept' => 'text/xml',
          'Content-Type' => 'text/xml'
        }
      ).
      to_return(status: 200, body: response_body.to_s, headers: {})
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

  # Recursively traverse a parsed JSON-LD structure and return prov:value's @value.
  def find_prov_value(obj)
    case obj
    when Hash
      prov_value = obj['prov:value'] || obj[:'prov:value']
      if prov_value.is_a?(Hash)
        value = prov_value['@value'] || prov_value[:'@value']
        return value unless value.nil?
      end

      obj.each_value do |value|
        result = find_prov_value(value)
        return result unless result.nil?
      end

      nil
    when Array
      obj.each do |item|
        result = find_prov_value(item)
        return result unless result.nil?
      end

      nil
    else
      nil
    end
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
