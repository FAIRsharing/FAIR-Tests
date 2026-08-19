# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_3_m_fs_community_support'

class FtR13MFsCommunitySupportTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MFsCommunitySupport

  def test_passes_when_search_support_links_follows_conditions
    stub_fairsharing_record(record_with_support_links([
                                                   {
                                                     'name' => 'Doc',
                                                     'type' => 'Help documentation',
                                                     'url'  => 'https://support.datacite.org/reference/introduction'
                                                   },
                                                   {
                                                     'name' => 'cont',
                                                     'type' => 'Contact form',
                                                     'url'  => 'https://contact/introduction'
                                                   }
                                                 ]))

    post '/test/ft_r1_3_m_fs_community_support',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'the resource provides community support channels.'
  end




  def test_fails_when_search_support_links_is_not_expected
    stub_fairsharing_record(record_with_support_links([
                                                        {
                                                          'name' => 'Doc',
                                                          'type' => 'Help documentation',
                                                          'url'  => 'https://support.datacite.org/reference/introduction'
                                                        },
                                                        {
                                                          'name' => 'Blog',
                                                          'type' => 'Blog/News',
                                                          'url'  => 'https://e/introduction'
                                                        }
                                                      ]))

    post '/test/ft_r1_3_m_fs_community_support',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_no_support_links_are_present
    stub_fairsharing_record(record_with_support_links([]))

    post '/test/ft_r1_3_m_fs_community_support',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end


  def test_fails_when_identifier_is_not_a_fairsharing_record
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

    post '/test/ft_r1_3_m_fs_community_support',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
    assert_includes last_response.body, 'A matching record was not found in FAIRsharing.'
  end



  def test_fail_not_database_standard_policy
    stub_request(:get, 'https://doi.org/10.1234%2F5678').to_return(
      status: 200,
      body: "https://fairsharing.org/5678".to_json,
      headers: headers
    )
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Collection",
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_3_m_fs_community_support',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'it is not a database, standard or policy.'
  end

  private

  def record_with_support_links(support_link)
    {
      'id' => '1234',
      'registry' => 'Database',
      'metadata' => {
        'support_links' => support_link
      }
    }
  end



  def stub_fairsharing_record(record)
    stub_request(:post, ENV['FAIRSHARING_API_URL']).
      with { |request| graphql_query(request).include?('fairsharingRecord') }.
      to_return(
        status: 200,
        body: {
          data: {
            fairsharingRecord: record
          }
        }.to_json,
        headers: headers
      )
  end

  def graphql_query(request)
    JSON.parse(request.body)['query']
  rescue JSON::ParserError
    ''
  end
end
