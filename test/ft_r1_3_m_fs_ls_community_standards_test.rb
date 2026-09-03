# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_3_m_fs_ls_community_standards'

class FtR13MFsLsCommunityStandardsTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MFsLsCommunityStandards

  def test_pass_ft_related_standards


    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "26",
            "registry": "Standard",
            "subjects":  [{
                            "id" => 1385,
                            "label" => "Biodiversity",
                            "ancestors" => [{"id" => 1381, "label" => "Life Science"}]
                          }
                        ]
          }
        }
      }.to_json,
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
            "subjects":  [{
                            "id" => 1385,
                            "label" => "Biodiversity",
                            "ancestors" => [{"id" => 1381, "label" => "Life Science"}]
                          }
            ],
            "recordAssociations": [
              {
                "recordAssocLabel": "shares_data_with",
                "linkedRecord": {
                  "registry": "Standard",
                  "type": "terminology_artefact",
                  "id": "26"
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_3_m_fs_ls_community_standards',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    end

  def test_pass_ft_related_standards_reverse
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Standard",
            "subjects":  [{
                            "id" => 1385,
                            "label" => "Biodiversity",
                            "ancestors" => [{"id" => 1381, "label" => "Life Science"}]
                          }
            ],
            "reverseRecordAssociations": [
              {
                "recordAssocLabel": "related_to",
                "fairsharingRecord": {
                  "registry": "Standard",
                  "type": "terminology_artefact",
                  "id": "26"
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_3_m_fs_ls_community_standards',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end


  def test_fail_no_life_sciece
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Standard",
            "subjects":  [{
                            "id" => 1385,
                            "label" => "Biodiversity",
                            "ancestors" => [{"id" => 1381, "label" => "Maths"}]
                          }
            ],
            "reverseRecordAssociations": [
              {
                "recordAssocLabel": "related_to",
                "fairsharingRecord": {
                  "registry": "Standard",
                  "type": "terminology_artefact",
                  "id": "26"
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_3_m_fs_ls_community_standards',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end


  def test_fail_ft_r1_3_m_fs_ls_community_standards
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Database",
            "subjects":[
              {"id": 21}
            ],
            "recordAssociations": [
              {
                "recordAssocLabel": "implements",
                "linkedRecord": {
                  "registry": "Standard",
                  "type": "identifier_schema"
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_3_m_fs_ls_community_standards',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fail_ft_r1_3_m_fs_deprecated_stadards
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Database",
            "subjects":[
              {"id": 21}
            ],
            "recordAssociations": [
              {
                "recordAssocLabel": "deprecates",
                "linkedRecord": {
                  "registry": "Standard",
                  "type": "reporting_guideline"
                }
              }
            ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_3_m_fs_ls_community_standards',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end


  def test_fail_not_correct_registry_ft_r1_3_m_fs_ls_community_standards
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

    post '/test/ft_r1_3_m_fs_ls_community_standards',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_indeterminate_ft_r1_3_m_fs_ls_community_standards
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

    post '/test/ft_r1_3_m_fs_ls_community_standards',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

end



