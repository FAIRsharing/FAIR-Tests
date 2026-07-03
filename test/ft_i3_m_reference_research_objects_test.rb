# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_i3_m_reference_research_objects'

class FtI3MReferenceResearchObjectsTest < Minitest::Test
  include ::TestHelper
  include ::FtI3MReferenceResearchObjects

  def test_passes_when_schema_reference_research_object
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
                'http://schema.org/creator' => [{'@id'=>'_:g2763436033'}]
              },
              {'@id' => '_:g46568022',
               '@type' => ['http://schema.org/CreativeWork'],
               '@url' => 'https://ora.ox.ac.uk/this/is/not/url.txt',
               'http://schema.org/name' =>
                 [{'@value' =>
                     'The effect of ambient and injection pressure on droplet size of ammonia sprays in a constant volume chamber'}]
              },
              {'@id' => '_:g2763436033',
               '@type' => ['http://schema.org/Person'],
               'http://schema.org/affiliation' => [{'@id'=>'_:g27634380'}],
               'http://schema.org/identifier' => [{'@id'=>'_:g27634400'}],
               'http://schema.org/name' => [{'@value'=>'Smith, S'}]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_related_research_object_has_no_url
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset'],
                'http://schema.org/isRelatedTo' => [{'@id'=>'_:g46568022'}]
              },
              {
                '@id' => '_:g46568022',
                '@type' => ['http://schema.org/CreativeWork'],
                'http://schema.org/name' => [{'@value' => 'A related publication without a URL'}]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_related_research_object_has_no_type
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset'],
                'http://schema.org/isRelatedTo' => [{'@id'=>'_:g46568022'}]
              },
              {
                '@id' => '_:g46568022',
                '@url' => '/objects/uuid:7f161a34-1d6c-40aa-9539-847a4ff00f44',
                'http://schema.org/name' => [{'@value' => 'A related publication without a type'}]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_no_reference_research_object
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

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_schema_no_reference_research_object_fill
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              {
                '@id' => 'uuid:example',
                '@type' => ['http://schema.org/Dataset'],
                'http://schema.org/isRelatedTo' => [],
                'http://schema.org/creator' => [{'@id'=>'_:g2763436033'}]
              }
            ]
          }
        ]
      }
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end
end
