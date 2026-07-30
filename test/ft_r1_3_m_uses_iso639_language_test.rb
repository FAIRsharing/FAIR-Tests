# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_3_m_uses_iso639_language'

class FtR13MUsesIso639LanguageTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MUsesIso639Language

  def test_passes_for_compact_iso639_language_data
    stub_language_jsonld(
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

  def test_passes_when_any_language_has_a_valid_iso639_url
    stub_language_jsonld(
      [
        {
          '@type' => 'Language',
          'name' => 'Invalid language entry',
          'sameAs' => 'https://example.org/vocabulary/language'
        },
        {
          '@type' => 'Language',
          'name' => 'French',
          'alternateName' => 'fre',
          'sameAs' => 'https://id.loc.gov/vocabulary/iso639-2/fre'
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_fails_for_non_registry_url_containing_iso639
    stub_language_jsonld(
      [
        {
          '@type' => 'Language',
          'name' => 'English',
          'sameAs' => 'https://example.org/iso639/eng'
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_iso639_term_is_not_a_three_letter_code
    stub_language_jsonld(
      [
        {
          '@type' => 'Language',
          'name' => 'Klingon',
          'sameAs' => 'https://id.loc.gov/vocabulary/iso639-2/klingon'
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_entry_is_not_a_language
    stub_language_jsonld(
      [
        {
          '@type' => 'Thing',
          'name' => 'English',
          'sameAs' => 'https://id.loc.gov/vocabulary/iso639-2/eng'
        }
      ]
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_language_field_is_missing
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'A record without language metadata' },
      resource_identifier: 'https://example.org/records/abc123'
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_language_entry_is_not_an_object
    stub_language_jsonld(['eng'])

    assert_metric_score 'fail'
  end

  private

  def stub_language_jsonld(languages)
    stub_request_jsonld(
      {
        '@type' => 'Dataset',
        'inLanguage' => languages
      },
      resource_identifier: 'https://example.org/records/abc123'
    )
  end

  def assert_metric_score(expected_score)
    post '/test/ft_r1_3_m_uses_iso639_language',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
