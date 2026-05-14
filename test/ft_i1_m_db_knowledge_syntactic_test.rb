# frozen_string_literal: true
require 'webmock/minitest'
require_relative './test_helper'
require_relative '../lib/fair_tests/ft_i1_m_db_knowledge_syntactic'

class FtI1MDbKnowledgeSyntacticTest < Minitest::Test
  include ::TestHelper
  include ::FtI1MDbKnowledgeSyntactic

  # TODO: These tests do not check for DOI resolution.
  # TODO: DOIs have been revised in https://github.com/FAIRsharing/FAIR-Tests/pull/36 which has not yet been merged.
  # TODO: Once it has been merged, a test can be added (though it is also tested in referenced PR).
  def test_is_syntactic
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "format": "syntactic"
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_i1_m_db_knowledge_syntactic',
         params: { resource_identifier: 'https://example.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_is_not_syntactic
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "123456",
            "registry": "Database",
            "format": "semantic"
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_i1_m_db_knowledge_syntactic',
         params: { resource_identifier: 'https://example.org/1234' }.to_json,
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
            "registry": "Standard",
            "format": nil
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_i1_m_db_knowledge_syntactic',
         params: { resource_identifier: 'https://example.org/1234' }.to_json,
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
        "data": {}
      }.to_json,
      headers: headers
    )

    post '/test/ft_i1_m_db_knowledge_syntactic',
         params: { resource_identifier: 'https://example.org/1234' }.to_json,
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

    post '/test/ft_i1_m_db_knowledge_syntactic',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

end