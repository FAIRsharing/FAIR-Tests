# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_a1_m_fs_db_open_access'

class FtA1MFsDbOpenAccessTest < Minitest::Test
  include ::TestHelper
  include ::FtA1MFsDbOpenAccess

  def test_passes_when_database_access_condition_type_is_open
    stub_fairsharing_record(database_record('data_access_condition' => { 'type' => 'open' }))

    post '/test/ft_a1_m_fs_db_open_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'the database has open or partially open data access'
  end

  def test_passes_when_database_access_condition_type_is_partially_open
    stub_fairsharing_record(database_record('data_access_condition' => { 'type' => 'partially open' }))

    post '/test/ft_a1_m_fs_db_open_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_database_access_condition_is_not_open
    stub_fairsharing_record(database_record('data_access_condition' => { 'type' => 'restricted' }))

    post '/test/ft_a1_m_fs_db_open_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'the database does not have open or partially open data access'
  end

  def test_fails_when_record_is_not_a_database
    stub_fairsharing_record({
                              'id' => '123456',
                              'registry' => 'Standard',
                              'metadata' => {
                                'data_access_condition' => { 'type' => 'open' }
                              }
                            })

    post '/test/ft_a1_m_fs_db_open_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'but it is not a database'
  end

  def test_resolves_doi_before_fairsharing_lookup
    stub_request(:get, 'https://doi.org/10.1234%2F5678').to_return(
      status: 200,
      body: 'https://fairsharing.org/5678'.to_json,
      headers: headers
    )
    stub_fairsharing_record(database_record('data_access_condition' => { 'type' => 'open' }))

    post '/test/ft_a1_m_fs_db_open_access',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_is_indeterminate_when_record_is_not_found
    stub_fairsharing_record(nil)

    post '/test/ft_a1_m_fs_db_open_access',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
    assert_includes last_response.body, 'No record was found matching the provided identifier.'
  end

  def test_api_description_is_available
    get '/test_descriptions/ft_a1_m_fs_db_open_access/api'

    assert last_response.ok?
    assert_includes last_response.body, 'x-tests_metric: "https://fairsharing.org/8381"'
    assert_includes last_response.body, 'x-applies_to_principle: "https://fairsharing.org/6293"'
    assert_includes last_response.body, 'This testassesses whether the FAIRsharing database record'
  end

  private

  def database_record(metadata)
    {
      'id' => '123456',
      'registry' => 'Database',
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
