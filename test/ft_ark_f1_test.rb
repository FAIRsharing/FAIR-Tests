# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_ark_f1'

class FtArkF1Test < Minitest::Test
  include ::TestHelper
  include ::FtArkF1


  def test_mints_persistent_identifiers
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "recordAssociations": [
              {
                "recordAssocLabel": "implements",
                "linkedRecord": {
                  "type": "identifier_schema",
                  "metadata": {
                    "persistent": true
                  }
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_ark_f1',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_does_not_mint_persistent_identifiers
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "recordAssociations": [
              {
                "recordAssocLabel": "implements",
                "linkedRecord": {
                  "type": "identifier_schema",
                  "metadata": {
                    "persistent": false
                  }
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_ark_f1',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_is_not_a_database
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Standard"
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_ark_f1',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_file_not_found
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {}
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_ark_f1',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end
end
