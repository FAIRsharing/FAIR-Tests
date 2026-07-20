# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_a1_m_fs_documents_comp_access'

class FtA1MFsDocumentsCompAccessTest < Minitest::Test
  include ::TestHelper
  include ::FtA1MFsDocumentsCompAccess

  def test_passes_when_read_process_uses_non_user_interface_access_with_documentation
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'API access',
                                                     'type' => 'read',
                                                     'access_method' => 'API',
                                                     'documentation_url' => 'https://example.org/api/docs'
                                                   }
                                                 ]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body,
                    'A non-user-interface process with read or read/write access and documentation was found.'
  end

  def test_passes_when_read_write_process_uses_non_user_interface_access_with_documentation
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'SPARQL endpoint',
                                                     'type' => 'read/write',
                                                     'access_method' => 'SPARQL endpoint',
                                                     'documentation_url' => 'http://example.org/sparql'
                                                   }
                                                 ]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_no_data_processes_are_present
    stub_fairsharing_record(record_with_processes([]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'No data processes found.'
  end

  def test_fails_when_data_processes_are_missing
    stub_fairsharing_record(record_with_metadata({}))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'No data processes found.'
  end

  def test_fails_when_read_process_uses_user_interface_access_with_documentation
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'Search records',
                                                     'type' => 'read',
                                                     'access_method' => 'User interface',
                                                     'documentation_url' => 'https://example.org/search'
                                                   }
                                                 ]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body,
                    'No non-user-interface process with read or read/write access and valid documentation was found'
  end

  def test_fails_when_non_user_interface_process_is_not_readable
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'API write',
                                                     'type' => 'write',
                                                     'access_method' => 'API',
                                                     'documentation_url' => 'https://example.org/api/docs'
                                                   }
                                                 ]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_matching_process_has_no_documentation_url
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'API access',
                                                     'type' => 'read',
                                                     'access_method' => 'API'
                                                   }
                                                 ]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_matching_process_has_invalid_documentation_url
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'API access',
                                                     'type' => 'read',
                                                     'access_method' => 'API',
                                                     'documentation_url' => 'not a url'
                                                   }
                                                 ]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_matching_process_has_non_http_documentation_url
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'API access',
                                                     'type' => 'read',
                                                     'access_method' => 'API',
                                                     'documentation_url' => 'ftp://example.org/docs'
                                                   }
                                                 ]))

    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_identifier_is_not_a_fairsharing_record
    post '/test/ft_a1_m_fs_documents_comp_access',
         params: { resource_identifier: 'https://example.org/not-a-fairsharing-record' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'No valid FAIRsharing record was found.'
  end

  def test_api_description_is_available
    get '/test_descriptions/ft_a1_m_fs_documents_comp_access/api'

    assert last_response.ok?
    assert_includes last_response.body, 'x-tests_metric: "https://fairsharing.org/8380"'
    assert_includes last_response.body, 'x-applies_to_principle: "https://fairsharing.org/6293"'
    assert_includes last_response.body, 'documents computational access'
  end

  private

  def record_with_processes(processes)
    record_with_metadata('data_processes_and_conditions' => processes)
  end

  def record_with_metadata(metadata)
    {
      'id' => '1234',
      'metadata' => metadata
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
