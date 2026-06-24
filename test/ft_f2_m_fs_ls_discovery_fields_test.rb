# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f2_m_fs_ls_discovery_fields'

class FtF2MFsLsDiscoveryFieldsTest < Minitest::Test
  include ::TestHelper
  include ::FtF2MFsLsDiscoveryFields

  def test_passes_when_fairsharing_record_has_required_life_science_fields
    stub_fairsharing_record(valid_record)
    stub_life_science_subject_hierarchy

    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_record_has_no_name
    stub_fairsharing_record(valid_record.merge('name' => ''))
    stub_life_science_subject_hierarchy

    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_description
    stub_fairsharing_record(valid_record.merge('description' => nil))
    stub_life_science_subject_hierarchy

    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_country
    stub_fairsharing_record(valid_record.merge('countries' => []))
    stub_life_science_subject_hierarchy

    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_object_types
    stub_fairsharing_record(valid_record.merge('objectTypes' => []))
    stub_life_science_subject_hierarchy

    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_subjects
    stub_fairsharing_record(valid_record.merge('subjects' => []))

    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_life_science_subject
    stub_fairsharing_record(valid_record.merge('subjects' => [{ 'label' => 'Engineering Science' }]))
    stub_life_science_subject_hierarchy

    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_is_indeterminate_when_record_cannot_be_obtained
    post '/test/ft_f2_m_fs_ls_discovery_fields',
         params: { resource_identifier: 'https://example.org/not-a-fairsharing-record' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

  def test_get_life_science_subjects_returns_life_science_descendant_names
    stub_life_science_subject_hierarchy

    assert_equal(
      ['life science', 'biology', 'molecular biology'],
      get_life_science_subjects
    )
  end

  def test_get_life_science_subjects_returns_empty_array_when_subject_is_absent
    stub_request(:post, ENV['FAIRSHARING_API_URL']).
      with { |request| graphql_query(request).include?('browseSubjects') }.
      to_return(
        status: 200,
        body: {
          data: {
            browseSubjects: {
              data: [
                {
                  id: 999,
                  name: 'Engineering Science',
                  children: []
                }
              ]
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_equal [], get_life_science_subjects
  end

  def test_get_life_science_subjects_uses_local_fallback_when_remote_fails
    stub_request(:post, ENV['FAIRSHARING_API_URL']).
      with { |request| graphql_query(request).include?('browseSubjects') }.
      to_return(status: 500, body: '{}')

    assert_equal [], get_life_science_subjects
  end

  def test_get_life_science_subjects_handles_remote_errors
    stub_request(:post, ENV['FAIRSHARING_API_URL']).
      with { |request| graphql_query(request).include?('browseSubjects') }.
      to_raise(StandardError)

    assert_equal [], get_life_science_subjects
  end

  private

  def valid_record
    {
      'name' => 'Life science resource',
      'description' => 'A resource with discovery metadata.',
      'countries' => [{ 'label' => 'United Kingdom' }],
      'objectTypes' => [{ 'id' => 1 }],
      'subjects' => [{ 'label' => 'Biology' }]
    }
  end

  def stub_fairsharing_record(record)
    stub_request(:post, ENV['FAIRSHARING_API_URL']).
      with { |request| graphql_query(request).include?('fairsharingRecord') }.
      to_return(
        status: 200,
        body: {
          data: {
            fairsharingRecord: record
          }
        }.to_json,
        headers: headers
      )
  end

  def stub_life_science_subject_hierarchy
    stub_request(:post, ENV['FAIRSHARING_API_URL']).
      with { |request| graphql_query(request).include?('browseSubjects') }.
      to_return(
        status: 200,
        body: {
          data: {
            browseSubjects: {
              data: [
                {
                  id: 999,
                  name: 'Engineering Science',
                  children: []
                },
                {
                  id: 1337,
                  name: 'Life Science',
                  children: [
                    {
                      id: 1456,
                      name: 'Biology',
                      children: [
                        {
                          id: 1384,
                          name: 'Molecular biology',
                          children: []
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def graphql_query(request)
    JSON.parse(request.body)['query']
  rescue JSON::ParserError
    ''
  end
end
