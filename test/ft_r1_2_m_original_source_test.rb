# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_original_source'

class FtR12MOriginalSourceTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MOriginalSource

  JSONLD_IDENTIFIER = 'https://example.org/records/abc123'
  DOI_IDENTIFIER = '10.1234/original-source-test'
  DATACITE_URL = "https://api.datacite.org/dois/#{DOI_IDENTIFIER}".freeze

  def test_passes_for_an_ora_deposit_in_jsonld
    stub_jsonld_source('ORA Deposit')

    assert_metric_score 'pass', JSONLD_IDENTIFIER
  end

  def test_fails_when_jsonld_does_not_name_an_ora_deposit
    stub_jsonld_source('A different source')

    assert_metric_score 'fail', JSONLD_IDENTIFIER
  end

  def test_passes_for_a_datacite_is_version_of_doi
    stub_datacite_identifier(identifier: '10.5287/ora-6raddkrg9', identifier_type: 'DOI')

    assert_metric_score 'pass', DOI_IDENTIFIER
  end

  def test_passes_for_a_datacite_is_version_of_url
    stub_datacite_identifier(identifier: 'https://example.org/original-source', identifier_type: 'URL')

    assert_metric_score 'pass', DOI_IDENTIFIER
  end

  def test_fails_for_a_different_datacite_relationship
    stub_datacite_identifier(
      identifier: '10.5287/ora-6raddkrg9',
      identifier_type: 'DOI',
      relation_type: 'References'
    )

    assert_metric_score 'fail', DOI_IDENTIFIER
  end

  def test_fails_for_an_invalid_datacite_identifier
    stub_datacite_identifier(identifier: 'not a DOI', identifier_type: 'DOI')

    assert_metric_score 'fail', DOI_IDENTIFIER
  end

  def test_fails_for_a_blank_datacite_identifier_of_another_type
    stub_datacite_identifier(identifier: '  ', identifier_type: 'ARK')

    assert_metric_score 'fail', DOI_IDENTIFIER
  end

  def test_indeterminate_when_no_jsonld_record_is_found
    stub_request_jsonld('', resource_identifier: JSONLD_IDENTIFIER)

    assert_metric_score 'indeterminate', JSONLD_IDENTIFIER
  end

  def test_indeterminate_when_no_datacite_record_is_found
    stub_datacite('')

    assert_metric_score 'indeterminate', DOI_IDENTIFIER
  end

  private

  def stub_jsonld_source(name)
    stub_request_jsonld(
      { 'isBasedOn' => { '@type' => 'Dataset', 'name' => name, 'url' => 'https://example.org/source' } },
      resource_identifier: JSONLD_IDENTIFIER
    )
  end

  def stub_datacite_identifier(identifier:, identifier_type:, relation_type: 'IsVersionOf')
    stub_datacite(
      'relatedIdentifiers' => [
        {
          'relationType' => relation_type,
          'relatedIdentifier' => identifier,
          'relatedIdentifierType' => identifier_type
        }
      ]
    )
  end

  def stub_datacite(response_body)
    body = response_body.is_a?(String) ? response_body : response_body.to_json
    stub_request(:get, DATACITE_URL)
      .with(headers: { 'Accept' => 'application/vnd.datacite.datacite+json' })
      .to_return(status: 200, body: body)
  end

  def assert_metric_score(expected_score, resource_identifier)
    post '/test/ft_r1_2_m_original_source',
         params: { resource_identifier: resource_identifier }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
