# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_3_m_fs_defines_community'

class FtR13MFsDefinesCommunityTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MFsDefinesCommunity

  def test_passes_when_there_is_valid_record_object_type
    stub_fairsharing_record(record_with_object_types([{
                                                       'id' => 13,
                                                       'label' => 'data'
                                                     },
                                                      {
                                                        'id' => 22,
                                                        'label' => 'software'
                                                      }
                                        ],
                                                     [{"id" => 1385, "label" => "Biodiversity"}]))

    post '/test/ft_r1_3_m_fs_defines_community',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'the resource defines its community.'
  end

  def test_fails_when_there_is_not_valid_object_type
    stub_fairsharing_record(record_with_object_types([{
                                                       'id' => 13,
                                                       'label' => 'object type not found'
                                                     }
                                        ],
                                                     [{"id" => 1385, "label" => "Biodiversity"}]           ))

    post '/test/ft_r1_3_m_fs_defines_community',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end



  def test_fails_when_no_object_types_are_present
    stub_fairsharing_record(record_with_object_types([],[]))

    post '/test/ft_r1_3_m_fs_defines_community',
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

    post '/test/ft_r1_3_m_fs_defines_community',
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

    post '/test/ft_r1_3_m_fs_defines_community',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'it is not a database, standard or policy.'
  end

  private

  def record_with_object_types(object_types, subjects)
    {
      'id' => '1234',
      'registry' => 'Database',
      'objectTypes' => object_types,
      'subjects' => subjects
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
