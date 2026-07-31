# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_creator_orcid'

class FtR12MCreatorOrcidTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MCreatorOrcid

  def test_passes_when_any_creator_has_a_valid_orcid_and_matching_url
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'name' => 'Creator without an ORCID'
        },
        {
          '@type' => 'Person',
          'name' => 'Garnett, A',
          'identifier' => {
            '@type' => 'PropertyValue',
            'propertyID' => 'ORCID',
            'value' => '0000-0002-1668-1029',
            'url' => 'https://orcid.org/0000-0002-1668-1029'
          }
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_fails_when_record_has_no_creators
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'A record without creators' },
      resource_identifier: 'https://example.org/records/abc123'
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_identifier_property_id_is_not_orcid
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'identifier' => {
            '@type' => 'PropertyValue',
            'propertyID' => 'LOCAL',
            'value' => '0000-0002-1668-1029',
            'url' => 'https://orcid.org/0000-0002-1668-1029'
          }
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_orcid_checksum_is_invalid
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'identifier' => {
            '@type' => 'PropertyValue',
            'propertyID' => 'ORCID',
            'value' => '0000-0002-1668-1028',
            'url' => 'https://orcid.org/0000-0002-1668-1028'
          }
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_orcid_url_does_not_match_the_id
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'identifier' => {
            '@type' => 'PropertyValue',
            'propertyID' => 'ORCID',
            'value' => '0000-0002-1668-1029',
            'url' => 'https://orcid.org/0000-0001-9572-0972'
          }
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_orcid_url_is_invalid
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'identifier' => {
            '@type' => 'PropertyValue',
            'propertyID' => 'ORCID',
            'value' => '0000-0002-1668-1029',
            'url' => 'not a URL'
          }
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_indeterminate_when_no_record_found
    stub_request_jsonld(
      '',
      resource_identifier: 'https://example.org/records/abc123'
    )

    assert_metric_score 'indeterminate'
  end

  private

  def stub_creator_jsonld(creators)
    stub_request_jsonld(
      {
        '@type' => 'Dataset',
        'creator' => creators
      },
      resource_identifier: 'https://example.org/records/abc123'
    )
  end

  def assert_metric_score(expected_score)
    post '/test/ft_r1_2_m_creator_orcid',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
