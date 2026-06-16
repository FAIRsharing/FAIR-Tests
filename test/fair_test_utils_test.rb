require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_test_utils'

unless defined?(Addressable::URI::InvalidURIError)
  module Addressable
    class URI
      class InvalidURIError < StandardError; end
    end
  end
end

class FairTestUtilsTest < Minitest::Test
  include TestHelper
  include FairTestUtils

  def test_handles_doi_metadata_errors
    stub_request(:get, "https://doi.org/10.12346%2Fwibble.ftang").
      with(
        headers: {
          'Accept'=>'application/vnd.citationstyles.csl+json'
        }).
      to_return(status: 500, body: "", headers: {})

    res = get_doi_metadata("10.12346/wibble.ftang")
    assert_equal res[:error].include?("Error parsing DOI metadata"), true
  end

  def test_metadata_harvesting_returns_parsed_json
    stub_metadata_harvesting({ title: "This record passes" })

    data = metadata_harvesting("https://example.org/records/abc123")
    assert has_matching_key_with_value?(data, %w[title])
  end

  def test_metadata_harvesting_returns_empty_graph_for_empty_rdf
    stub_metadata_harvesting({})

    assert_equal [], metadata_harvesting("https://example.org/records/abc123")
  end

  def test_metadata_harvesting_returns_nil_for_invalid_jsonld
    fake_rdf = Object.new
    fake_rdf.define_singleton_method(:dump) { |_format| 'not json' }

    fake_data = Object.new
    fake_data.define_singleton_method(:rdf) { fake_rdf }

    with_stubbed_harvester_resolveit(fake_data) do
      assert_nil metadata_harvesting("https://example.org/records/invalid-jsonld")
    end
  end

  def test_remote_metadata_harvesting_returns_parsed_json
    resource_identifier = "https://example.org/records/abc123"

    stub_request(:post, "https://tools.ostrails.eu/champion/harvest_only").
      with(
        body: { resource_identifier: resource_identifier }.to_json,
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      ).
      to_return(
        status: 200,
        body: { title: "Remote record passes" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_equal(
      { 'title' => 'Remote record passes' },
      remote_metadata_harvesting(resource_identifier)
    )
  end

  def test_remote_metadata_harvesting_returns_nil_for_empty_body
    resource_identifier = "https://example.org/records/empty"

    stub_request(:post, "https://tools.ostrails.eu/champion/harvest_only").
      with(
        body: { resource_identifier: resource_identifier }.to_json,
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      ).
      to_return(
        status: 200,
        body: "  \n",
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_nil remote_metadata_harvesting(resource_identifier)
  end

  def test_remote_metadata_harvesting_returns_nil_for_invalid_json
    resource_identifier = "https://example.org/records/invalid-json"

    stub_request(:post, "https://tools.ostrails.eu/champion/harvest_only").
      with(
        body: { resource_identifier: resource_identifier }.to_json,
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      ).
      to_return(
        status: 200,
        body: "not json",
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_nil remote_metadata_harvesting(resource_identifier)
  end

  def test_contains_meaningful_value_covers_all_value_types
    refute contains_meaningful_value?(nil)

    assert contains_meaningful_value?("title")
    refute contains_meaningful_value?("  ")

    assert contains_meaningful_value?(1)
    refute contains_meaningful_value?(0)

    assert contains_meaningful_value?(["title"])
    refute contains_meaningful_value?([])

    assert contains_meaningful_value?({ title: "A title" })
    refute contains_meaningful_value?({})
    assert contains_meaningful_value?({ '@id' => 'https://example.org/records/abc123' })
    refute contains_meaningful_value?({ :'@id' => '  ' })

    assert contains_meaningful_value?(false)
  end

  def test_finds_schema_property_value_triples
    data = {
      '@graph' => [
        {
          '@id' => 'urn:local:harvester:graph',
          'local:triples' => [
            {
              '@id' => 'uuid:example',
              '@type' => ['http://schema.org/Dataset']
            },
            {
              '@id' => '_:identifier',
              '@type' => ['http://schema.org/PropertyValue'],
              'http://schema.org/propertyID' => [{ '@value' => 'DOI' }],
              'http://schema.org/url' => [{ '@id' => 'https://doi.org/10.1234/example' }]
            }
          ]
        }
      ]
    }

    matches = find_schema_property_value_triples(data)

    assert_equal 1, matches.length
    assert_equal ['DOI'], schema_object_values(matches.first, 'propertyID')
    assert_equal ['https://doi.org/10.1234/example'], schema_object_values(matches.first, 'url')
  end

  def test_find_schema_object_values
    data = {
      '@graph' => [
        {
          '@id' => 'urn:local:harvester:graph',
          'local:triples' => [
            {
              '@id' => [1, 2],
              '@type' => ['http://schema.org/Dataset']
            },
            {
              '@id' => '_:identifier',
              '@type' => ['http://schema.org/PropertyValue'],
              'http://schema.org/propertyID' => [{ '@value' => 'DOI' }],
              'http://schema.org/url' => [{ '@id' => 'https://doi.org/10.1234/example' }]
            }
          ]
        }
      ]
    }

    matches = find_schema_object_values(data,'@id')

    assert_equal 4, matches.length
    assert_equal [1, 2], matches[1]
    assert_equal 'https://doi.org/10.1234/example', matches[3]
  end

  def test_find_all_schema_object_key_value
    data = {
      '@graph' => [
        {
          '@id' => 'urn:local:harvester:graph',
          'local:triples' => [
            {
              '@id' => [1, 2],
              '@type' => ['http://schema.org/Dataset']
            },
            {
              '@id' => '_:identifier',
              '@type' => ['http://schema.org/PropertyValue'],
              'http://schema.org/propertyID' => [{ '@value' => 'DOI' }],
              'http://schema.org/url' => [{ '@id' => '_:identifier' }]
            }
          ]
        }
      ]
    }

    matches = find_all_schema_object_key_value(data,'@id', '_:identifier')

    assert_equal 2, matches.length
    assert_equal ['http://schema.org/PropertyValue'], matches[0]['@type']
    assert_equal 1, matches[1].keys.length
  end

  def test_jsonld_scalar_values_covers_supported_shapes
    assert_equal ['literal'], jsonld_scalar_values({ '@value' => 'literal' })
    assert_equal ['symbol literal'], jsonld_scalar_values({ :'@value' => 'symbol literal' })
    assert_equal ['https://example.org/id'], jsonld_scalar_values({ '@id' => 'https://example.org/id' })
    assert_equal ['symbol-id'], jsonld_scalar_values({ :'@id' => 'symbol-id' })
    assert_equal [], jsonld_scalar_values({})

    assert_equal [], jsonld_scalar_values(nil)
    assert_equal ['plain'], jsonld_scalar_values('plain')
    assert_equal [1], jsonld_scalar_values(1)

    assert_equal(
      ['nested literal', 'nested-id', 'plain'],
      jsonld_scalar_values([
                             { '@value' => 'nested literal' },
                             { :'@id' => 'nested-id' },
                             'plain',
                             nil,
                             {}
                           ])
    )
  end

  def test_resolves_dois
    fake_request = Object.new
    def fake_request.last_uri
      raise Addressable::URI::InvalidURIError, 'invalid uri'
    end

    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:body) { '"https://example.org/records/abc123"' }
    fake_response.define_singleton_method(:request) { fake_request }

    httparty_singleton = HTTParty.singleton_class
    httparty_singleton.alias_method :__original_get_for_test_resolves_dois, :get
    httparty_singleton.remove_method :get
    httparty_singleton.define_method(:get) do |*_args, **_kwargs|
      fake_response
    end

    assert_equal 'https://example.org/records/abc123',
                 resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
  ensure
    if defined?(httparty_singleton) && httparty_singleton.method_defined?(:__original_get_for_test_resolves_dois)
      httparty_singleton.remove_method :get
      httparty_singleton.alias_method :get, :__original_get_for_test_resolves_dois
      httparty_singleton.remove_method :__original_get_for_test_resolves_dois
    end

    stub_request(:get, "https://example.org").
      with(
        headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: "", headers: {})


      assert_equal 'https://example.org/', resolve_doi('https://example.org/')
  end

  def test_resolve_doi_handles_invalid_resolved_uri
    invalid_uri = 'http://[invalid'

    fake_request = Object.new
    fake_request.define_singleton_method(:last_uri) { invalid_uri }

    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:body) { '"https://example.org/records/abc123"' }
    fake_response.define_singleton_method(:request) { fake_request }

    with_stubbed_httparty_get(response: fake_response) do
      assert_equal invalid_uri,
                   resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
    end
  end

  def test_resolve_doi_handles_timeouts
    with_stubbed_httparty_get(error: Net::OpenTimeout.new('execution expired')) do
      assert_nil resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
    end
  end

  def test_resolve_doi_returns_nil_for_blank_input
    assert_nil resolve_doi(nil)
    assert_nil resolve_doi('')
    assert_nil resolve_doi('   ')
  end

  def test_resolve_doi_returns_nil_for_unsuccessful_response
    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { false }

    with_stubbed_httparty_get(response: fake_response) do
      assert_nil resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
    end
  end

  def test_resolve_doi_uses_body_url_when_redirect_stays_on_doi_org
    fake_request = Object.new
    fake_request.define_singleton_method(:last_uri) { URI('https://doi.org/10.25504/FAIRsharing.123456') }

    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:body) { 'https://example.org/records/abc123' }
    fake_response.define_singleton_method(:request) { fake_request }

    with_stubbed_httparty_get(response: fake_response) do
      assert_equal 'https://example.org/records/abc123',
                   resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
    end
  end

  def test_resolve_doi_returns_nil_when_redirect_stays_on_doi_org_without_body_url
    fake_request = Object.new
    fake_request.define_singleton_method(:last_uri) { URI('https://doi.org/10.25504/FAIRsharing.123456') }

    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:body) { '{"message":"still resolving"}' }
    fake_response.define_singleton_method(:request) { fake_request }

    with_stubbed_httparty_get(response: fake_response) do
      assert_nil resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
    end
  end

  def test_resolve_doi_returns_nil_for_success_without_resolved_or_body_url
    fake_request = Object.new
    fake_request.define_singleton_method(:last_uri) { nil }

    fake_response = Object.new
    fake_response.define_singleton_method(:success?) { true }
    fake_response.define_singleton_method(:body) { '{"message":"no target"}' }
    fake_response.define_singleton_method(:request) { fake_request }

    with_stubbed_httparty_get(response: fake_response) do
      assert_nil resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
    end
  end

  def test_resolve_doi_handles_read_timeouts
    with_stubbed_httparty_get(error: Net::ReadTimeout.new('execution expired')) do
      assert_nil resolve_doi('https://doi.org/10.25504/FAIRsharing.123456')
    end
  end


  def test_normalizes_dois
    assert_equal "https://doi.org/10.25504%2FFAIRsharing.123456",
                 normalize_doi_url("doi:10.25504/FAIRsharing.123456")
    assert_equal "https://doi.org/10.25504%2FFAIRsharing.123456",
                 normalize_doi_url("10.25504/FAIRsharing.123456")
  end

  def test_obtains_record_from_text
    assert_nil obtain_record_from_text("https://example.org")

    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456"
          }
        }
      }.to_json,
      headers: headers
    )
    assert_equal obtain_record_from_text("https://fairsharing.org/FAIRsharing.123456"), {"id" => "123456"}
  end

  def test_handles_errors_getting_fairsharing_record
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").to_return(
      status: 404,
      body: {
        "message": "Not Found"
      }.to_json
    )

    assert_equal get_fairsharing_record("FAIRsharing.123456"), {:message=>"Error getting record from FAIRsharing API: 404, "}
  end

  def test_handles_malformed_fairsharing_record_response
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").to_return(
      status: 200,
      body: 'not json',
      headers: headers
    )

    assert_equal({}, get_fairsharing_record("FAIRsharing.123456"))
  end

  def test_handles_find_by_regex_errors
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").to_return(
      status: 404,
      body: {
        "message": "Not Found"
      }.to_json
    )
    assert_equal find_by_regex("FAIRsharing.123456"), {:message=>"Error getting record from FAIRsharing API: 404, "}
  end


  private

  def with_stubbed_harvester_resolveit(response)
    harvester_singleton = FAIRChampionHarvester::Core.singleton_class
    original_method = :__original_resolveit_for_fair_test_utils_test
    harvester_singleton.alias_method original_method, :resolveit
    harvester_singleton.remove_method :resolveit
    harvester_singleton.define_method(:resolveit) do |_url|
      response
    end

    yield
  ensure
    if defined?(harvester_singleton) && harvester_singleton.method_defined?(original_method)
      harvester_singleton.remove_method :resolveit if harvester_singleton.method_defined?(:resolveit)
      harvester_singleton.alias_method :resolveit, original_method
      harvester_singleton.remove_method original_method
    end
  end

  def with_stubbed_httparty_get(response: nil, error: nil)
    httparty_singleton = HTTParty.singleton_class
    original_method = :__original_get_for_fair_test_utils_test
    httparty_singleton.alias_method original_method, :get
    httparty_singleton.remove_method :get
    httparty_singleton.define_method(:get) do |*_args, **_kwargs|
      raise error if error

      response
    end

    yield
  ensure
    if defined?(httparty_singleton) && httparty_singleton.method_defined?(original_method)
      httparty_singleton.remove_method :get if httparty_singleton.method_defined?(:get)
      httparty_singleton.alias_method :get, original_method
      httparty_singleton.remove_method original_method
    end
  end

end
