# frozen_string_literal: true

require 'webmock/minitest'
require_relative './test_helper'
require_relative '../lib/fair_tests/ft_r1_3_m_recognised_structured_metadata'

class FtR11MDatabaseLevelLicensesTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MRecognisedStructuredMetadata

  def test_has_structured_metadata
    stub_request(:post, "https://tools.ostrails.eu/champion/harvest_only")
      .with(
        body: "{\"resource_identifier\":\"https://fairsharing.org/FAIRsharing.1414v8\"}",
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200,
                 body: {
                   '@graph': [
                     {
                       'local:comments': [
                         'INFO: Found jsonld application/ld+json type of content'
                       ]
                     }
                   ]
                 }.to_json,
                 headers: {})

    post '/test/ft_r1_3_m_recognised_structured_metadata',
         params: { resource_identifier: 'https://fairsharing.org/FAIRsharing.1414v8' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_has_no_structured_metadata
    stub_request(:post, "https://tools.ostrails.eu/champion/harvest_only")
      .with(
        body: "{\"resource_identifier\":\"https://fairsharing.org/FAIRsharing.1414v8\"}",
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200,
                 body: {
                   '@graph': [
                     {
                       'local:comments': [
                         'INFO: This record is a dreadful failure'
                       ]
                     }
                   ]
                 }.to_json,
                 headers: {})

    post '/test/ft_r1_3_m_recognised_structured_metadata',
         params: { resource_identifier: 'https://fairsharing.org/FAIRsharing.1414v8' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_no_record_was_found
    stub_request(:post, "https://tools.ostrails.eu/champion/harvest_only")
      .with(
        body: "{\"resource_identifier\":\"https://fairsharing.org/FAIRsharing.1414v8\"}",
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200,
                 body: {}.to_json,
                 headers: {})

    post '/test/ft_r1_3_m_recognised_structured_metadata',
         params: { resource_identifier: 'https://fairsharing.org/FAIRsharing.1414v8' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end
end
