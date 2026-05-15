# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f2_m_discoverypublisher'

class FtF2MDiscoverypublisherTest < Minitest::Test
  include ::TestHelper
  include ::FtF2MDiscoverypublisher

  #################
  # passing tests #
  #################
  def test_is_doi_and_passes

    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").to_return(
      status: 200,
      body: {
        publisher: "This record passes publishing co."
      }.to_json,
      headers: headers
    )

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://doi.org/10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_resolve_doi_then_passes
    stub_request(:get, "https://doi.org/10.25504%2FFAIRsharing.9kahy4").
      to_return(
        status: 200,
        body: "https://example.org/records/abc123".to_json,
        headers: headers
      )
    stub_metadata_harvesting({
      publisher: "This record passes publishing co."
    })

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://doi.org/10.25504/FAIRsharing.9kahy4'}.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_non_doi_passes
    stub_metadata_harvesting({
      publisher: "This record passes publishing co."
    })

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://example.org/records/abc123'}.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_is_doi_and_fails_then_resolution_passes

    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      with(headers: datacite_headers).to_return(
      status: 200,
      body: {
        gibberish: "no publisher here!"
      }.to_json,
      headers: headers
    )
    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      with { |request| request.headers['Accept'] != datacite_headers['Accept'] }.
      to_return(
        status: 200,
        body: "https://example.org/records/abc123".to_json,
        headers: headers
      )
    stub_metadata_harvesting({
      publisher: "This record passes publishing co."
    })

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://doi.org/10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end



  #################
  # failing tests #
  #################
  def test_is_doi_and_fails_then_resolution_fails

    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      with(headers: datacite_headers).to_return(
      status: 200,
      body: {
        gibberish: "this record fails"
      }.to_json,
      headers: headers
    )
    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      with { |request| request.headers['Accept'] != datacite_headers['Accept'] }.
      to_return(
        status: 200,
        body: "https://example.org/records/abc123".to_json,
        headers: headers
      )
    stub_metadata_harvesting({})

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://doi.org/10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_is_doi_and_fails

    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      with(headers: datacite_headers).to_return(
      status: 200,
      body: {
        codename: "This record fails"
      }.to_json,
      headers: headers
    )
    # resolve_doi performs a second GET without Datacite headers.
    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      to_return(
        status: 200,
        body: "https://example.org/records/abc123".to_json,
        headers: headers
      )
    stub_metadata_harvesting({
      codename: "This record fails"
    })

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://doi.org/10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_is_not_doi_and_fails

    stub_metadata_harvesting({
      codename: "This record fails"
    })

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  #######################
  # indeterminate tests #
  #######################
  def test_is_doi_and_indeterminate

    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      with(headers: datacite_headers).to_return(
      status: 200,
      body: {}.to_json,
      headers: headers
    )
    # resolve_doi performs a second GET without Datacite headers.
    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      to_return(
        status: 200,
        body: "https://example.org/records/abc123".to_json,
        headers: headers
      )
    stub_metadata_harvesting({})

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://doi.org/10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

  def test_is_not_doi_and_indeterminate

    stub_metadata_harvesting({})

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

  #######################
  # Tests with ORA data #
  #######################
  def test_ora_data_passes
    json_file = JSON.load_file('test/fixtures/example_pass_fixture.json')
    stub_metadata_harvesting(json_file)

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_ora_data_fails
    json_file = JSON.load_file('test/fixtures/example_fail_discoverypublisher_fixture.json')
    stub_metadata_harvesting(json_file)

    post '/test/ft_f2_m_discoverypublisher',
         params: { resource_identifier: 'https://example.org/records/abc123' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end
end
