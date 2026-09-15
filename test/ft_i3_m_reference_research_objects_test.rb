# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_i3_m_reference_research_objects'

class FtI3MReferenceResearchObjectsTest < Minitest::Test
  include ::TestHelper
  include ::FtI3MReferenceResearchObjects

  def test_passes_when_subject_of_contains_a_creative_work
    stub_request_jsonld(
      {
        'subjectOf' => [
          {
            '@type' => 'CreativeWork',
            'name' => 'A related research object',
            'url' => 'https://ora.ox.ac.uk/objects/uuid:related'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end


  def test_passes_when_is_related_to_contains_a_scholarly_article
    stub_request_jsonld(
      {
        'isRelatedTo' => [
          {
            '@type' => 'ScholarlyArticle',
            'name' => 'A related publication',
            'url' => 'https://ora.ox.ac.uk/objects/uuid:publication'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_related_research_object_has_no_url
    stub_request_jsonld(
      {
        'isRelatedTo' => [
          {
            '@type' => 'CreativeWork',
            'name' => 'A related publication without a URL'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_related_research_object_has_no_type
    stub_request_jsonld(
      {
        'isRelatedTo' => [
          {
            'name' => 'A related publication without a type',
            'url' => 'https://ora.ox.ac.uk/objects/uuid:related'
          }
        ]
      },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_no_reference_research_object
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'An unconnected research object' },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_related_research_object_field_is_empty
    stub_request_jsonld(
      { '@type' => 'Dataset', 'isRelatedTo' => [] },
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_indeterminate_when_no_record_found
    stub_request_jsonld(
      '',
      resource_identifier: 'https://example.org/records/abc123'
    )

    post '/test/ft_i3_m_reference_research_objects',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end
end
