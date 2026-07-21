# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_a2_m_dbpersistencepolicy'

class FtA2MDbpersistencepolicyTest < Minitest::Test
  include ::TestHelper
  include ::FtA2MDbpersistencepolicy

  def test_ft_a2_m_dbpersistencepolicy_passes
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "metadata": {
              "data_preservation_policy": {
                "url": "https://www.what_an_url.klo"
              }
            }
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_a2_m_dbpersistencepolicy',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_ft_a2_m_dbpersistencepolicy_fails
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "metadata": {
              "data_preservation_policy": {
                "url": ""
              }
            }
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_a2_m_dbpersistencepolicy',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_ft_a2_m_dbpersistencepolicy_is_indeterminate
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

    post '/test/ft_a2_m_dbpersistencepolicy',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

  def test_is_not_a_database_via_doi
    stub_request(:get, 'https://doi.org/10.1234%2F5678').to_return(
      status: 200,
      body: "https://fairsharing.org/5678".to_json,
      headers: headers
    )
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Standard",
            "format": nil
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_a2_m_dbpersistencepolicy',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

end
