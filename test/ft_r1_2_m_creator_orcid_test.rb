# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_creator_orcid'

class FtR12MCreatorOrcidTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MCreatorOrcid

  def test_passes_when_schema_property_value_triple_creator_orcid
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset'],
                "http://schema.org/creator"=>[{"@id"=>"_:g2763436033"}]
              },
              {"@id"=>"_:g2763436033",
               "@type"=>["http://schema.org/Person"],
               "http://schema.org/affiliation"=>[{"@id"=>"_:g27634380"}],
               "http://schema.org/identifier"=>[{"@id"=>"_:g27634400"}],
               "http://schema.org/name"=>[{"@value"=>"Smith, S"}]
              },
              {"@id"=>"_:g27634400",
               "@type"=>["http://schema.org/PropertyValue"],
               "http://schema.org/propertyID"=>[{"@value"=>"ORCID"}],
               "http://schema.org/url"=>[{"@id"=>"https://orcid.org/0000-0002-2780-7819"}],
               "http://schema.org/value"=>[{"@value"=>"0000-0002-2780-7819"}]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_r1_2_m_creator_orcid',
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

    post '/test/ft_r1_2_m_creator_orcid',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_schema_property_value_and_no_matched_orcid
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset'],
                "http://schema.org/creator"=>[{"@id"=>"_:g2763436033"}]
              },
              {"@id"=>"_:g2763436033",
               "@type"=>["http://schema.org/Person"],
               "http://schema.org/affiliation"=>[{"@id"=>"_:g27634380"}],
               "http://schema.org/identifier"=>[{"@id"=>"_:g27634400"}],
               "http://schema.org/name"=>[{"@value"=>"Smith, S"}]
              },
              {"@id"=>"_:g276344001",
               "@type"=>["http://schema.org/PropertyValue"],
               "http://schema.org/propertyID"=>[{"@value"=>"ORCID"}],
               "http://schema.org/url"=>[{"@id"=>"https://orcid.org/0000-0002-2780-7819"}],
               "http://schema.org/value"=>[{"@value"=>"0000-0002-2780-7819"}]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_r1_2_m_creator_orcid',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end
end
