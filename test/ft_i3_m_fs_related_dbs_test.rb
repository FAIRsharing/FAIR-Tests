# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_i3_m_fs_related_dbs'

class FtI3MFsRelatedDbsTest < Minitest::Test
  include ::TestHelper
  include ::FtI3MFsRelatedDbs

  def test_pass_ft_i3_m_fs_related_dbs
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Database",
            "recordAssociations": [
              {
                "recordAssocLabel": "shares_data_with",
                "linkedRecord": {
                  "registry": "Database"
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_i3_m_fs_related_dbs',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fail_ft_i3_m_fs_related_dbs
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Database",
            "recordAssociations": [
              {
                "recordAssocLabel": "implements",
                "linkedRecord": {
                  "type": "identifier_schema"
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_i3_m_fs_related_dbs',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fail_not_database_ft_i3_m_fs_related_dbs
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

    post '/test/ft_i3_m_fs_related_dbs',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_indeterminate_ft_i3_m_fs_related_dbs
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

    post '/test/ft_i3_m_fs_related_dbs',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end
end