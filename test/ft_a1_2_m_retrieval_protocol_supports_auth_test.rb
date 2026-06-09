# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_a1_2_m_retrieval_protocol_supports_auth'

class FtA12MRetrievalProtocolSupportsAuthTest < Minitest::Test
  include ::TestHelper
  include ::FtA12MRetrievalProtocolSupportsAuth

  def test_database_access_condition_open
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "metadata": {
              "data_access_condition": "open"
            }
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_a1_2_m_retrieval_protocol_supports_auth',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_database_access_condition_not_found
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "metadata": {
              "data_access_condition": "not_found"
            }
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_a1_2_m_retrieval_protocol_supports_auth',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_record_is_not_a_database
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Not a database"
          }
        }
      }.to_json
    )

    post '/test/ft_a1_2_m_retrieval_protocol_supports_auth',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_record_is_not_found
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {}
      }.to_json
    )

    post '/test/ft_a1_2_m_retrieval_protocol_supports_auth',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

end