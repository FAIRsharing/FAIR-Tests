# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_3_m_fs_db_trust_recognition'

class FtR13MFsDbTrustRecognitionTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MFsDbTrustRecognition

  def test_passes_with_valid_certification
    stub_fairsharing_record(record_with_metadata(
                              {
                              'certifications_and_community_badges' => [
                                  {
                                    'name'=> 'certificate',
                                    'url' => 'https:www.certificate.tes'
                                  }
                                ]
                                }
                            ))

    post '/test/ft_r1_3_m_fs_db_trust_recognition',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'the database demonstrates external trust or recognition.'
  end


  def test_fails_with_valid_certification
    stub_fairsharing_record(record_with_metadata({'certifications_and_community_badges' => []}))

    post '/test/ft_r1_3_m_fs_db_trust_recognition',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fail_not_database
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
            "registry": "Standard",
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_3_m_fs_db_trust_recognition',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'The record exists in FAIRsharing but it is not a database.'
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

    post '/test/ft_r1_3_m_fs_db_trust_recognition',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
    assert_includes last_response.body, 'A matching record was not found in FAIRsharing.'
  end

  private

  def record_with_metadata(metadata)
    {
      'id' => '1234',
      'metadata' => metadata,
      'registry' => 'Database'
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
