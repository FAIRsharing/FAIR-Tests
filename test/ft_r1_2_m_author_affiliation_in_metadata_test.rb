# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_author_affiliation_in_metadata'

class FtR12MAuthorAffiliationInMetadataTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MAuthorAffiliationInMetadata

  def test_passes_when_a_creator_has_a_named_organization_affiliation
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'name' => 'Siefring, J',
          'affiliation' => {
            '@type' => 'Organization',
            'name' => 'University of Oxford, GLAM, BDLSS'
          }
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_passes_when_any_creator_has_a_named_organization_affiliation
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'name' => 'Creator without an affiliation'
        },
        {
          '@type' => 'Person',
          'schema:affiliation' => [
            {
              'schema:@type' => 'Organization',
              'schema:name' => 'University of Oxford'
            }
          ]
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_fails_when_record_has_no_creators
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'A record without creators' },
      resource_identifier: resource_identifier
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_affiliation_is_not_an_organization
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'affiliation' => {
            '@type' => 'Person',
            'name' => 'A named person'
          }
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_organization_name_is_blank
    stub_creator_jsonld(
      [
        {
          '@type' => 'Person',
          'affiliation' => {
            '@type' => 'Organization',
            'name' => '  '
          }
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_is_indeterminate_when_metadata_is_unavailable
    stub_request_jsonld('', resource_identifier: resource_identifier)

    assert_metric_score 'indeterminate'
  end

  private

  def resource_identifier
    'https://example.org/records/abc123'
  end

  def stub_creator_jsonld(creators)
    stub_request_jsonld(
      {
        '@type' => 'Dataset',
        'creator' => creators
      },
      resource_identifier: resource_identifier
    )
  end

  def assert_metric_score(expected_score)
    post '/test/ft_r1_2_m_author_affiliation_in_metadata',
         params: { resource_identifier: resource_identifier }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
