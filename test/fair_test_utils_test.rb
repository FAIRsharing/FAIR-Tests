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
