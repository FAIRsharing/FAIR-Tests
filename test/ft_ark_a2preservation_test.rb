# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_ark_a2preservation'

class FtArkA2preservationTest < Minitest::Test
  include ::TestHelper
  include ::FtArkA2preservation

  def test_pass_ft_ark_a2preservation
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

    post '/test/ft_ark_a2preservation',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'pass'
  end

  def test_fail_ft_ark_a2preservation
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

    post '/test/ft_ark_a2preservation',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'fail'
  end

  def test_indeterminate_ft_ark_a2preservation
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

    post '/test/ft_ark_a2preservation',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'indeterminate'
  end
end
