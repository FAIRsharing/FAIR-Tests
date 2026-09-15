# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_ror_id_for_funder'

class FtR12MRorIdForFunderTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MRorIdForFunder

  def test_passes_when_named_grant_funder_has_matching_ror_value_and_url
    stub_funding_jsonld(
      [
        grant_with_funder(
          ror_identifier(
            value: 'https://ror.org/0439y7842',
            url: 'https://ror.org/0439y7842'
          )
        )
      ]
    )

    assert_metric_score 'pass'
  end

  def test_passes_when_ror_identifier_has_a_valid_bare_value
    stub_funding_jsonld(
      [grant_with_funder(ror_identifier(value: '0439y7842'))]
    )

    assert_metric_score 'pass'
  end

  def test_passes_when_ror_identifier_has_a_valid_url_only
    stub_funding_jsonld(
      [grant_with_funder(ror_identifier(url: 'https://ror.org/0439y7842'))]
    )

    assert_metric_score 'pass'
  end

  def test_fails_when_funding_is_missing
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'An unfunded record' },
      resource_identifier: 'https://example.org/records/abc123'
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_funding_entry_is_not_a_grant
    funding = grant_with_funder(ror_identifier(value: '0439y7842'))
    funding['@type'] = 'Organization'
    stub_funding_jsonld([funding])

    assert_metric_score 'fail'
  end

  def test_fails_when_funder_name_is_blank
    grant = grant_with_funder(ror_identifier(value: '0439y7842'))
    grant['funder']['name'] = '  '
    stub_funding_jsonld([grant])

    assert_metric_score 'fail'
  end

  def test_fails_when_identifier_is_not_labelled_ror
    stub_funding_jsonld(
      [
        grant_with_funder(
          ror_identifier(value: '0439y7842', property_id: 'LOCAL')
        )
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_ror_value_and_url_are_invalid
    stub_funding_jsonld(
      [
        grant_with_funder(
          ror_identifier(
            value: 'invalid-ror',
            url: 'https://example.org/0439y7842'
          )
        )
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_ror_belongs_to_a_creator_instead_of_a_funder
    stub_request_jsonld(
      {
        '@type' => 'Dataset',
        'creator' => [
          {
            '@type' => 'Person',
            'name' => 'A creator',
            'affiliation' => {
              '@type' => 'Organization',
              'name' => 'An institution',
              'identifier' => ror_identifier(value: '0439y7842')
            }
          }
        ],
        'funding' => [
          {
            '@type' => 'Grant',
            'funder' => {
              '@type' => 'Organization',
              'name' => 'A funder without a ROR'
            }
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
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

  def ror_identifier(value: nil, url: nil, property_id: 'ROR')
    {
      '@type' => 'PropertyValue',
      'propertyID' => property_id,
      'value' => value,
      'url' => url
    }.compact
  end

  def grant_with_funder(identifier)
    {
      '@type' => 'Grant',
      'identifier' => 'EP/V04673X/1',
      'funder' => {
        '@type' => 'Organization',
        'name' => 'Engineering and Physical Sciences Research Council',
        'identifier' => identifier
      }
    }
  end

  def stub_funding_jsonld(funding)
    stub_request_jsonld(
      {
        '@type' => 'Dataset',
        'funding' => funding
      },
      resource_identifier: 'https://example.org/records/abc123'
    )
  end

  def assert_metric_score(expected_score)
    post '/test/ft_r1_2_m_ror_id_for_funder',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
