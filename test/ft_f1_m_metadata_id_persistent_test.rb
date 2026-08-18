# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f1_m_metadata_id_persistent'

class FtF1MMetadataIdPersistentTest < Minitest::Test
  include ::TestHelper
  include ::FtF1MMetadataIdPersistent

  def test_passes_when_identifier_contains_doi_with_valid_url
    stub_request_jsonld(
      {
        'identifier' => [
          {
            '@type' => 'PropertyValue',
            'propertyID' => 'DOI',
            'value' => '10.1234/example',
            'url' => 'https://doi.org/10.1234/example'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_f1_m_metadata_id_persistent',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_passes_when_identifier_contains_ark_with_valid_url
    stub_request_jsonld(
      {
        'identifier' => [
          {
            '@type' => 'PropertyValue',
            'propertyID' => 'ARK',
            'value' => 'ark:/12345/example',
            'url' => 'https://n2t.net/ark:/12345/example'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_f1_m_metadata_id_persistent',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_passes_when_identifier_is_not_labelled_as_doi_but_fairsharing_marks_it_persistent
    stub_request_jsonld(
      {
        'identifier' => [
          {
            '@type' => 'PropertyValue',
            'propertyID' => 'UNKNOWN',
            'url' => 'https://doi.org/10.1234/example'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "regex": {
            "records": [
              {
                "id": "123456",
                "metadata": {
                  "persistent": true
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_f1_m_metadata_id_persistent',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_no_identifiers_exist
    stub_request_jsonld(
      { 'name' => 'Example record' },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_f1_m_metadata_id_persistent',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_doi_identifier_has_an_invalid_url
    stub_request_jsonld(
      {
        'identifier' => [
          {
            '@type' => 'PropertyValue',
            'propertyID' => 'DOI',
            'value' => '10.1234/example',
            'url' => 'not a URL'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_f1_m_metadata_id_persistent',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_indeterminate_when_no_record_found
    stub_request_jsonld(
      {},
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_f1_m_metadata_id_persistent',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end
end
