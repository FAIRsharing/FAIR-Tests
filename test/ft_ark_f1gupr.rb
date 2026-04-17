# frozen_string_literal: true
require 'webmock/minitest'
require_relative './test_helper'
require_relative '../lib/fair_tests/ft_ark_f1gupr'

class FtArkF1Test < Minitest::Test
  include ::TestHelper
  include ::FtArkF1

  def test_pass_ft_ark_f1gupr1
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
                  "type": "identifier_schema",
                  "metadata": {
                    "persistent": true,
                    "globally_unique": true,
                    "resolvable": true
                  }
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_ark_f1gupr1',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'pass'
  end

  def test_fail_ft_ark_f1gupr1
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
                  "type": "identifier_schema",
                  "metadata": {
                    "persistent": true,
                    "globally_unique": false
                  }
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_ark_f1gupr1',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'fail'
  end

  def test_indeterminate_ft_ark_f1gupr1
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

    post '/test/ft_ark_f1gupr1',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'indeterminate'
  end
end