# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_ror_id_for_funder'

class FtR12MRorIdForFunderTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MRorIdForFunder

  def test_passes_when_schema_property_value_triple_contains_ror
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
                'http://schema.org/propertyID' => [{ '@value' => 'ROR' }],
                'http://schema.org/url' => [{ '@id' => 'https://ror.org/0439y7842' }]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_r1_2_m_ror_id_for_funder',
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

    post '/test/ft_r1_2_m_ror_id_for_funder',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_schema_property_value_not_labelled_as_and_not_ror
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
                'http://schema.org/url' => [{ '@id' => 'https://example.com/not_a_ror' }]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_r1_2_m_ror_id_for_funder',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end
end
