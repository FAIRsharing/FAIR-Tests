# frozen_string_literal: true
require 'webmock/minitest'
require_relative './test_helper'
require_relative '../lib/fair_tests/ft_r1_2_m_fs_resource_contact'

class FtR12MFsResourceContactTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MFsResourceContact

  def test_has_a_contact
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
        status: 200,
        body: {
          "data": {
            "fairsharingRecord": {
              "id": '123456',
              "registry": 'Database',
              "metadata": {
                'contacts': [
                  {"contact_name": 'Sherry', 'contact_email': 'sherry@travel.uel'}
                ]
              }
            }
          }
        }.to_json,
        headers: headers
    )

    post '/test/ft_r1_2_m_fs_resource_contact',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end

  def test_has_no_a_contact_has_support
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
        status: 200,
        body: {
          "data": {
            "fairsharingRecord": {
              "id": '123456',
              "registry": 'Database',
              "metadata": {
                'contacts': [],
                "support_links": [
                  {'type': 'Contact form'}
                ]
              }
            }
          }
        }.to_json,
        headers: headers
    )

    post '/test/ft_r1_2_m_fs_resource_contact',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end


  def test_has_no_a_contact_has_no_support
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
        status: 200,
        body: {
          "data": {
            "fairsharingRecord": {
              "id": '123456',
              "registry": 'Database',
              "metadata": {
                'contacts': [],
                "support_links": [
                  {'type': 'Github'}
                ]
              }
            }
          }
        }.to_json,
        headers: headers
    )

    post '/test/ft_r1_2_m_fs_resource_contact',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_is_not_a_database_collection_standard
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
        status: 200,
        body: {
          "data": {
            "fairsharingRecord": {
              "id": '123456',
              "registry": 'Collection',
              "licences": [
                {
                  id: 1
                }
              ]
            }
          }
        }.to_json,
        headers: headers
    )

    post '/test/ft_r1_2_m_fs_resource_contact',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
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

    post '/test/ft_r1_2_m_fs_resource_contact',
         params: { resource_identifier: 'https://example.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

  def test_is_not_a_db_st_policy_via_doi
    stub_request(:get, 'https://doi.org/10.1234%2F5678').to_return(
      status: 200,
      body: 'https://fairsharing.org/5678'.to_json,
      headers: headers
    )
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": '123456',
            "registry": 'Collection',
            "licences": [
              {
                id: 1
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_2_m_fs_resource_contact',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

end
