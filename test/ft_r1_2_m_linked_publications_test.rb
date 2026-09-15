# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_linked_publications'

class FtR12MLinkedPublicationsTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MLinkedPublications

  def test_passes_for_each_permitted_publication_type
    FtR12MLinkedPublications::PUBLICATION_RELATIONSHIP_FIELDS.each do |field|
      FtR12MLinkedPublications::PERMITTED_PUBLICATION_TYPES.each do |type|
        stub_permitted_fields(
          field,
          [
            {
              '@type' => type,
              'name' => "A linked #{type}",
              'url' => 'https://ora.ox.ac.uk/objects/uuid:publication'
            }
          ]
        )

        assert_metric_score 'pass'
      end
    end
  end

  def test_passes_when_any_relationship_is_a_valid_linked_publication
    FtR12MLinkedPublications::PUBLICATION_RELATIONSHIP_FIELDS.each do |field|
      stub_permitted_fields(
        field,
        [
          {
            '@type' => 'WebPage',
            'name' => 'Not a permitted publication',
            'url' => 'https://example.org/page'
          },
          {
            '@type' => 'ScholarlyArticle',
            'name' => 'A linked publication',
            'url' => 'https://ora.ox.ac.uk/objects/uuid:publication'
          }
        ]
      )

      assert_metric_score 'pass'
    end
  end

  def test_fails_when_relationship_fields_are_missing
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'A record without linked publications' },
      resource_identifier: 'https://example.org/records/abc123'
    )

    assert_metric_score 'fail'
  end

  def test_fails_when_publication_type_is_not_permitted
    FtR12MLinkedPublications::PUBLICATION_RELATIONSHIP_FIELDS.each do |field|
      stub_permitted_fields(
        field,
        [
          {
            '@type' => 'WebPage',
            'name' => 'An unsupported related object',
            'url' => 'https://example.org/page'
          }
        ]
      )

      assert_metric_score 'fail'
    end
  end

  def test_fails_when_publication_name_is_blank
    FtR12MLinkedPublications::PUBLICATION_RELATIONSHIP_FIELDS.each do |field|
      stub_permitted_fields(
        field,
        [
          {
            '@type' => 'CreativeWork',
            'name' => '  ',
            'url' => 'https://example.org/publication'
          }
        ]
      )

      assert_metric_score 'fail'
    end
  end

  def test_fails_when_publication_url_is_invalid
    FtR12MLinkedPublications::PUBLICATION_RELATIONSHIP_FIELDS.each do |field|
      stub_permitted_fields(
        field,
        [
          {
            '@type' => 'Book',
            'name' => 'A linked book',
            'url' => 'not a URL'
          }
        ]
      )

      assert_metric_score 'fail'
    end
  end

  def test_indeterminate_when_no_record_found
    stub_request_jsonld(
      '',
      resource_identifier: 'https://example.org/records/abc123'
    )

    assert_metric_score 'indeterminate'
  end

  private

  def stub_permitted_fields(field, publications)
    stub_request_jsonld(
      {
        field => publications
      },
      resource_identifier: 'https://example.org/records/abc123'
    )
  end

  def assert_metric_score(expected_score)
    post '/test/ft_r1_2_m_linked_publications',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
