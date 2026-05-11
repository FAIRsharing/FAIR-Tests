# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f1_m_idgloballyunique'

class FtF1MIdgloballyuniqueTest < Minitest::Test
  include ::TestHelper
  include ::FtF1MIdgloballyunique

  def test_is_globally_unique
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "regex": {
            "records": [
              {
                "id": "123456",
                "metadata": {
                  "globally_unique": true
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_f1_m_idgloballyunique',
         params: { resource_identifier: '10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_is_not_globally_unique
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "regex": {
            "records": [
              {
                "id": "123456",
                "metadata": {}
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_f1_m_idgloballyunique',
         params: { resource_identifier: '10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_is_not_found
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

    post '/test/ft_f1_m_idgloballyunique',
         params: { resource_identifier: '10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

end
