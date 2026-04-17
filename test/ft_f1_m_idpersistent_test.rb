# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f1_m_idpersistent'

class FtF1MIdpersistentTest < Minitest::Test
  include ::TestHelper
  include ::FtF1MIdpersistent

  def test_is_persistent
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
                  "persistent": true
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_f1_m_idpersistent',
         params: { resource_identifier: '10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'pass'
  end

  def test_is_not_persistent
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

    post '/test/ft_f1_m_idpersistent',
         params: { resource_identifier: '10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'fail'
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

    post '/test/ft_f1_m_idpersistent',
         params: { resource_identifier: '10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'indeterminate'
  end

end
