# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_i3_m_fs_human_submission'

class FtI3MFsHumanSubmissionTest < Minitest::Test
  include ::TestHelper
  include ::FtI3MFsHumanSubmission

  def test_passes_when_search_process_uses_user_interface_for_write
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'Search records',
                                                     'type' => 'write',
                                                     'access_method' => 'User interface'
                                                   }
                                                 ]))

    post '/test/ft_i3_m_fs_human_submission',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'the database allows content submission by humans.'
  end

  def test_passes_when_browse_process_uses_user_interface_for_read_write
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'Browse datasets',
                                                     'type' => 'read/write',
                                                     'access_method' => 'User interface'
                                                   }
                                                 ]))

    post '/test/ft_i3_m_fs_human_submission',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end


  def test_fails_when_search_process_is_not_user_interface
    stub_fairsharing_record(record_with_processes([
                                                    {
                                                      'name' => 'Browse datasets',
                                                      'type' => 'read/write',
                                                      'access_method' => 'API'
                                                    }
                                                  ]))

    post '/test/ft_i3_m_fs_human_submission',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_no_data_processes_are_present
    stub_fairsharing_record(record_with_processes([]))

    post '/test/ft_i3_m_fs_human_submission',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end


  def test_fails_when_user_interface_process_is_not_writable
    stub_fairsharing_record(record_with_processes([
                                                   {
                                                     'name' => 'Search records',
                                                     'type' => 'read',
                                                     'access_method' => 'User interface'
                                                   }
                                                 ]))

    post '/test/ft_i3_m_fs_human_submission',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end


  def test_fails_when_identifier_is_not_a_fairsharing_record
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "regex": {
            "records": []
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_i3_m_fs_human_submission',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
    assert_includes last_response.body, 'A matching record was not found in FAIRsharing.'
  end



  def test_fail_not_database
    stub_request(:get, 'https://doi.org/10.1234%2F5678').to_return(
      status: 200,
      body: "https://fairsharing.org/5678".to_json,
      headers: headers
    )
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Standard",
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_i3_m_fs_human_submission',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'it is not a database.'
  end

  private

  def record_with_processes(processes)
    {
      'id' => '1234',
      'registry' => 'Database',
      'metadata' => {
        'data_processes_and_conditions' => processes
      }
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
