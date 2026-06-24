# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f2_m_fs_discovery_fields'

class FtF2MFsDiscoveryFieldsTest < Minitest::Test
  include ::TestHelper
  include ::FtF2MFsDiscoveryFields

  def test_passes_when_fairsharing_record_has_required_discovery_fields
    stub_fairsharing_record(valid_record)

    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_record_has_no_name
    stub_fairsharing_record(valid_record.merge('name' => ''))

    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_description
    stub_fairsharing_record(valid_record.merge('description' => nil))

    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_country
    stub_fairsharing_record(valid_record.merge('countries' => []))

    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_object_types
    stub_fairsharing_record(valid_record.merge('objectTypes' => []))

    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_record_has_no_subjects
    stub_fairsharing_record(valid_record.merge('subjects' => []))

    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_accepts_any_subject_without_life_science_hierarchy_check
    stub_fairsharing_record(valid_record.merge('subjects' => [{ 'label' => 'Engineering Science' }]))

    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_is_indeterminate_when_record_cannot_be_obtained
    post '/test/ft_f2_m_fs_discovery_fields',
         params: { resource_identifier: 'https://example.org/not-a-fairsharing-record' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

  private

  def valid_record
    {
      'name' => 'FAIRsharing resource',
      'description' => 'A resource with discovery metadata.',
      'countries' => [{ 'label' => 'United Kingdom' }],
      'objectTypes' => [{ 'id' => 1 }],
      'subjects' => [{ 'label' => 'Engineering Science' }]
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

  def graphql_query(request)
    JSON.parse(request.body)['query']
  rescue JSON::ParserError
    ''
  end
end
