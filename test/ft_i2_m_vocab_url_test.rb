# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_i2_m_vocab_url'

class FtI2MVocabUrlTest < Minitest::Test
  include ::TestHelper
  include ::FtI2MVocabUrl

  RESOURCE_IDENTIFIER = 'https://example.org/records/abc123'

  def test_passes_when_language_contains_a_valid_vocabulary_url
    stub_languages(
      [
        {
          '@type' => 'Language',
          'name' => 'English',
          'alternateName' => 'eng',
          'sameAs' => 'http://id.loc.gov/vocabulary/iso639-2/eng'
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_passes_when_any_language_contains_a_valid_vocabulary_url
    stub_languages(
      [
        {
          '@type' => 'Language',
          'sameAs' => 'not a URL'
        },
        {
          '@type' => 'Language',
          'sameAs' => 'https://example.org/vocabularies/french'
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_passes_for_a_jsonld_id_vocabulary_url
    stub_languages(
      [
        {
          '@type' => 'Language',
          'sameAs' => { '@id' => 'https://example.org/vocabularies/english' }
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_fails_when_vocabulary_url_is_not_well_formed
    stub_languages(
      [
        {
          '@type' => 'Language',
          'sameAs' => 'not a URL'
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_language_field_is_missing
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'A record without language metadata' },
      resource_identifier: RESOURCE_IDENTIFIER
    )

    assert_metric_score 'fail'
  end

  def test_is_indeterminate_when_no_record_is_found
    stub_request_jsonld({}, resource_identifier: RESOURCE_IDENTIFIER)

    assert_metric_score 'indeterminate'
  end

  def test_api_description_is_available
    get '/test_descriptions/ft_i2_m_vocab_url/api'

    assert last_response.ok?
    assert_includes last_response.body,
                    'x-tests_metric: "https://fairsharing.org/10.25504/FAIRsharing.0273a2"'
    assert_includes last_response.body,
                    'x-applies_to_principle: "https://fairsharing.org/FAIRsharing.96d4af"'
    assert_includes last_response.body, 'FAIR Test - I2 - Metadata - Vocabulary URL'
  end

  private

  def stub_languages(languages)
    stub_request_jsonld(
      {
        '@type' => 'Dataset',
        'inLanguage' => languages
      },
      resource_identifier: RESOURCE_IDENTIFIER
    )
  end

  def assert_metric_score(expected_score)
    post '/test/ft_i2_m_vocab_url',
         params: { resource_identifier: RESOURCE_IDENTIFIER }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
