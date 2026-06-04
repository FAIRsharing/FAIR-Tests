# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_3_m_uses_iso639_language.rb'

class FtR12MCreatorOrcidTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MUsesIso639Language

  def test_passes_when_schema_property_value_iso639
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              { "@id" => "_:g27634560",
                "@type" => ["http://schema.org/Language"],
                "http://schema.org/alternateName" => [{ "@value" => "eng" }],
                "http://schema.org/name" => [{ "@value" => "English" }],
                "http://schema.org/sameAs" => [{ "@id" => "http://id.loc.gov/vocabulary/iso639-2/eng" }] },
            ]
          }
        ]
      }
    )

    post '/test/ft_r1_3_m_uses_iso639_language',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_schema_property_value_not_iso639
    stub_metadata_harvesting(
      {
        '@graph' => [
          {
            '@id' => 'urn:local:harvester:graph',
            'local:triples' => [
              { "@id" => "_:g27634560",
                "@type" => ["http://schema.org/Language"],
                "http://schema.org/alternateName" => [{ "@value" => "eng" }],
                "http://schema.org/name" => [{ "@value" => "English" }],
                "http://schema.org/sameAs" => [{ "@id" => "http://id.loc.gov/vocabulary/something_else/klingon" }] },
            ]
          }
        ]
      }
    )

    post '/test/ft_r1_3_m_uses_iso639_language',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_schema_property_value_iso639_missing
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

    post '/test/ft_r1_3_m_uses_iso639_language',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end
end
