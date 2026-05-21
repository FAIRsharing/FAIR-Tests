# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f1_m_metadata_id_unique'

class FtF1MMetadataIdUniqueTest < Minitest::Test
  include ::TestHelper
  include ::FtF1MMetadataIdUnique

  def test_passes_when_schema_property_value_triple_contains_doi
    stub_metadata_harvesting(
      {
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
    )

    post '/test/ft_f1_m_metadata_id_unique',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_passes_when_schema_property_value_not_labelled_as_doi
    stub_metadata_harvesting(
      {
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
                'http://schema.org/propertyID' => [{ '@value' => 'UNKNOWN' }],
                'http://schema.org/url' => [{ '@id' => 'https://doi.org/10.1234/example' }]
              }
            ]
          }
        ]
      }
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
                  "globally_unique": true
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_f1_m_metadata_id_unique',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_no_schema_property_value_triples_exist
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset']
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_f1_m_metadata_id_unique',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_schema_property_value_not_labelled_as_and_not_doi
    stub_metadata_harvesting(
      {
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
                'http://schema.org/propertyID' => [{ '@value' => 'UNKNOWN' }],
                'http://schema.org/url' => [{ '@id' => 'https://example.com/not_a_doi' }]
              }
            ]
          }
        ]
      }
    )
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "regex": {
            "records": []
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_f1_m_metadata_id_unique',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end
end
