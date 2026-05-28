# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_a1_1_m_https_retrieval_protocol'

class FtR12MRorIdForFunderTest < Minitest::Test
  include ::TestHelper
  include ::FtA11MHttpsRetrievalProtocol

  def test_passes_when_https_url
    stub_request(:head, 'https://example.org/records/abc123')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: '', headers: {})

    post '/test/ft_a1_1_m_https_retrieval_protocol',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_http_url
    stub_request(:head, 'https://example.org/records/abc123')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 418, body: '', headers: {})

    post '/test/ft_a1_1_m_https_retrieval_protocol',
         params: { resource_identifier: 'http://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_passes_when_url_has_no_scheme
    stub_request(:head, 'https://example.org/records/abc123')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: '', headers: {})

    post '/test/ft_a1_1_m_https_retrieval_protocol',
         params: { resource_identifier: 'example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_fails_when_https_retrieval_raises_ssl_error
    stub_request(:head, 'https://example.org/records/abc123')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_raise(OpenSSL::SSL::SSLError.new('certificate verify failed'))

    post '/test/ft_a1_1_m_https_retrieval_protocol',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'certificate verify failed'
  end
end
