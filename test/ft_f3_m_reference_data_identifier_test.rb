# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f3_m_reference_data_identifier'

class FtF3MReferenceDataIdentifierTest < Minitest::Test
  include ::TestHelper
  include ::FtF3MReferenceDataIdentifier

  def test_passes_when_schema_reference_data_identifier
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset'],
                'http://schema.org/isRelatedTo' => [{'@id'=>'_:g46568022'}],
                'http://schema.org/creator' => [{'@id'=>'_:g2763436033'}],
                "http://schema.org/distribution"=>[{"@id"=>"_:g46558032"}]
              },
              { "@id" => "_:g46558032",
                "http://schema.org/identifier"=>[{"@id"=>"_:g465600"}]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_f3_m_reference_data_identifier',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_schema_reference_data_identifier
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset'],
                'http://schema.org/isRelatedTo' => [{'@id'=>'_:g46568022'}],
                'http://schema.org/creator' => [{'@id'=>'_:g2763436033'}],
                "http://schema.org/distribution"=>[{"@id"=>"_:g46558032"}]
              },
              { "@id" => "_:g46558032",
                "http://schema.org/identifier"=>[]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_f3_m_reference_data_identifier',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_schema_reference_data_identifier_missing
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => []
          }
        ]
      }
    )

    post '/test/ft_f3_m_reference_data_identifier',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end
end
