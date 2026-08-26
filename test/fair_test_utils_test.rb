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
          'Accept' => 'application/vnd.citationstyles.csl+json'
        }).
      to_return(status: 500, body: "", headers: {})

    res = get_doi_metadata("10.12346/wibble.ftang")
    assert_equal res[:error].include?("Error parsing DOI metadata"), true
  end

  def test_request_jsonld_returns_parsed_json_or_nil
    valid_url = "https://ora.ox.ac.uk/objects/uuid:valid"
    empty_url = "https://ora.ox.ac.uk/objects/uuid:"
    invalid_json_url = "https://ora.ox.ac.uk/objects/uuid:invalid"

    stub_request_jsonld({ title: "This ORA record passes" }, resource_identifier: valid_url)
    stub_request_jsonld("", resource_identifier: empty_url)
    stub_request_jsonld("not json", resource_identifier: invalid_json_url)

    assert_equal({ "title" => "This ORA record passes" }, request_jsonld(valid_url))
    assert_nil request_jsonld(empty_url)
    assert_nil request_jsonld(invalid_json_url)
  end

  def test_request_datacite_accepts_doi_urls_and_bare_dois
    doi_url = 'https://doi.org/10.1234/example'
    bare_doi = '10.1234/example'
    datacite_url = "https://api.datacite.org/dois/#{bare_doi}"
    response_body = { data: { id: bare_doi } }.to_json
    request_headers = { 'Accept' => 'application/vnd.datacite.datacite+json' }

    stub_request(:get, doi_url).
      with(headers: request_headers).
      to_return(body: response_body)
    stub_request(:get, datacite_url).
      with(headers: request_headers).
      to_return(body: response_body)

    expected = { 'data' => { 'id' => bare_doi } }
    assert_equal expected, request_datacite(doi_url)
    assert_equal expected, request_datacite(bare_doi)
  end

  def test_request_datacite_rejects_non_dois
    assert_nil request_datacite(nil)
    assert_nil request_datacite('not a DOI')
  end

  def test_request_datacite_returns_nil_for_malformed_json
    doi = '10.1234/malformed-response'

    stub_request(:get, "https://api.datacite.org/dois/#{doi}").
      with(headers: { 'Accept' => 'application/vnd.datacite.datacite+json' }).
      to_return(status: 200, body: 'not json')

    assert_nil request_datacite(doi)
  end

  def test_search_searxng_posts_search_term_and_requests_json
    url = 'https://search.fairsharing.org/search'
    response_body = { results: [{ title: 'Linacre School of Defence' }] }.to_json

    stub_request(:post, url).
      with(
        body: { q: 'linacre school of defence', format: 'json' },
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      ).
      to_return(body: response_body)

    expected = [{ 'results' => [{ 'title' => 'Linacre School of Defence' }]}, 200]
    assert_equal expected, search_searxng('linacre school of defence')
  end

  def test_search_searxng_returns_status_for_empty_and_malformed_responses
    url = 'https://search.fairsharing.org/search'

    stub_request(:post, url).
      with(body: { q: 'empty response', format: 'json' }).
      to_return(status: 204, body: '')
    stub_request(:post, url).
      with(body: { q: 'malformed response', format: 'json' }).
      to_return(status: 502, body: 'not json')

    assert_equal [nil, 204], search_searxng('empty response')
    assert_equal [nil, 502], search_searxng('malformed response')
  end

  def test_search_core_gets_encoded_title_and_returns_json_with_status
    original_core_api_key = ENV['CORE_API_KEY']
    ENV['CORE_API_KEY'] = 'test-core-api-key'

    title = 'Linacre School of Defence'
    url = 'https://api.core.ac.uk/v3/search/outputs'
    response_body = { results: [{ title: title }] }.to_json

    stub_request(:get, url).
      with(
        query: { q: title },
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'Bearer: test-core-api-key'
        }
      ).
      to_return(status: 200, body: response_body)

    expected = [{ 'results' => [{ 'title' => title }] }, 200]
    assert_equal expected, search_core(title)
  ensure
    if original_core_api_key.nil?
      ENV.delete('CORE_API_KEY')
    else
      ENV['CORE_API_KEY'] = original_core_api_key
    end
  end

  def test_search_core_returns_status_for_empty_and_malformed_responses
    url = 'https://api.core.ac.uk/v3/search/outputs'

    stub_request(:get, url).
      with(query: { q: 'empty response' }).
      to_return(status: 204, body: '')
    stub_request(:get, url).
      with(query: { q: 'malformed response' }).
      to_return(status: 502, body: 'not json')

    assert_equal [nil, 204], search_core('empty response')
    assert_equal [nil, 502], search_core('malformed response')
  end

  def test_validates_xml
    assert valid_xml?('<resource><title>A title</title></resource>')

    refute valid_xml?('<resource>')
    refute valid_xml?('')
    refute valid_xml?(nil)
  end

  def test_request_xml_returns_content_or_nil
    valid_url = 'https://example.org/valid.xml'
    invalid_url = 'https://example.org/invalid.xml'
    empty_url = 'https://example.org/empty.xml'
    error_url = 'https://example.org/error.xml'

    stub_request_xml('<resource />', resource_identifier: valid_url)
    stub_request_xml('<resource>', resource_identifier: invalid_url)
    stub_request_xml('', resource_identifier: empty_url)
    stub_request(:get, error_url).to_raise(StandardError)

    assert_equal '<resource />', request_xml(valid_url)
    assert_nil request_xml(invalid_url)
    assert_nil request_xml(empty_url)
    assert_nil request_xml(error_url)
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

    assert contains_meaningful_value?(false)
  end

  def test_funding_value_present_covers_nested_hashes_arrays_and_values
    assert funding_value_present?(
      { 'funder' => [nil, { 'name' => 'Engineering and Physical Sciences Research Council' }] }
    )
    refute funding_value_present?(
      { 'funder' => [nil, { 'name' => '  ' }] }
    )
  end

  def test_finds_top_level_jsonld_discovery_fields
    fields = %w(name creator contributor datePublished)

    assert has_top_level_jsonld_discovery_field?({ 'name' => 'A title' }, fields)
    assert has_top_level_jsonld_discovery_field?({ creator: [{ name: 'A creator' }] }, fields)
    assert has_top_level_jsonld_discovery_field?({ 'schema:contributor' => ['A contributor'] }, fields)
    assert has_top_level_jsonld_discovery_field?(
      { 'http://schema.org/datePublished' => '2026-07-29' },
      fields
    )

    refute has_top_level_jsonld_discovery_field?({ 'codename' => 'Not a title' }, fields)
    refute has_top_level_jsonld_discovery_field?({ 'name' => '  ' }, fields)
    refute has_top_level_jsonld_discovery_field?({ 'publisher' => { 'name' => 'Nested' } }, fields)
    refute has_top_level_jsonld_discovery_field?(nil, fields)
  end

  def test_validates_orcid_ids
    assert valid_orcid_id?('0000-0002-1668-1029')
    assert valid_orcid_id?('0000-0002-9079-593X')

    refute valid_orcid_id?('0000-0002-1668-1028')
    refute valid_orcid_id?('0000000216681029')
    refute valid_orcid_id?(nil)
  end

  def test_validates_iso639_2_urls
    assert valid_iso639_2_url?('http://id.loc.gov/vocabulary/iso639-2/eng')
    assert valid_iso639_2_url?('https://id.loc.gov/vocabulary/iso639-2/FRE')

    refute valid_iso639_2_url?('https://example.org/vocabulary/iso639-2/eng')
    refute valid_iso639_2_url?('https://id.loc.gov/vocabulary/iso639-1/en')
    refute valid_iso639_2_url?('https://id.loc.gov/vocabulary/iso639-2/english')
    refute valid_iso639_2_url?('https://id.loc.gov/vocabulary/iso639-2/eng?source=test')
    refute valid_iso639_2_url?(nil)
  end

  def test_validates_ror_ids_and_urls
    assert valid_ror_id?('0439y7842')
    refute valid_ror_id?('invalid-ror')
    refute valid_ror_id?(nil)

    assert valid_ror_url?('https://ror.org/0439y7842')
    refute valid_ror_url?('http://ror.org/0439y7842')
    refute valid_ror_url?('https://example.org/0439y7842')
    refute valid_ror_url?('https://ror.org/invalid-ror')
    refute valid_ror_url?('https://ror.org/0439y7842?source=test')
    refute valid_ror_url?(nil)
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

    matches = find_schema_object_values(data, '@id')

    assert_equal 5, matches.length
    assert_equal [1, 2], matches[1, 2]
    assert_equal 'https://doi.org/10.1234/example', matches[4]
  end

  def test_schema_object_values_covers_supported_property_keys_and_shapes
    data = {
      'identifier' => '10.1234/plain',
      identifier: { '@value' => '10.1234/symbol' },
      'schema:identifier' => [{ '@id' => 'https://doi.org/10.1234/prefixed' }],
      :'http://schema.org/identifier' => { '@value' => '10.1234/uri' }
    }

    assert_equal(
      [
        '10.1234/plain',
        '10.1234/symbol',
        'https://doi.org/10.1234/prefixed',
        '10.1234/uri'
      ],
      schema_object_values(data, 'identifier')
    )
    assert_equal [], schema_object_values([], 'identifier')
    assert_equal [], schema_object_values(nil, 'identifier')
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
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
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

    assert_equal get_fairsharing_record("FAIRsharing.123456"), {:message => "Error getting record from FAIRsharing API: 404, "}
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
    assert_equal find_by_regex("FAIRsharing.123456"), {:message => "Error getting record from FAIRsharing API: 404, "}
  end

  def test_validates_subjects_ids
    assert subject_appears_or_descendent([1, 2, 3], [{'id' => 1}])
    assert subject_appears_or_descendent([1, 2, 3], [{'id' => 5}, 'ancestors' => [{'id' => 11}, {'id' => 3}]])
    refute subject_appears_or_descendent([1, 2, 3], [{'id' => 22}])
    refute subject_appears_or_descendent([1, 2, 3], [{'id' => 5}, 'ancestors' => [{'id' => 11}, {'id' => 33}]])
  end

  private

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
