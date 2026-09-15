# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_fs_funding_organisation'

class FtR12MFsFundingOrganisationTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MFsFundingOrganisation

  def test_pass_ft_related_organisations

    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Standard",
            "subjects":[
              {"id": 21}
            ],
            "organisationLinks":
              [{"id": 5023,
                "relation": "funds",
                "fairsharingRecord": {"id": 73},
                "organisation": {"id": 2035, "name": "National Institutes of Health"},
                "grant": nil,
                "isLead": false},
               {"id": 11559,
                "relation": "funds",
                "fairsharingRecord": {"id": 73},
                "organisation": {"id": 3555, "name": "NIH Common Fund"},
                "grant": nil,
                "isLead": false},
               {"id": 15844,
                "relation": "maintains",
                "fairsharingRecord": {"id": 73},
                "organisation": {"id": 1304, "name": "Icahn School of Medicine at Mount Sinai"},
                "grant": nil,
                "isLead": false}
              ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_2_m_fs_funding_organisation',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end


  def test_fail_ft_r1_2_m_fs_funding_organisation
    stub_request(:post, "#{ENV['FAIRSHARING_API_URL']}").
      with(headers: headers).to_return(
      status: 200,
      body: {
        "data": {
          "fairsharingRecord": {
            "id": "1234567",
            "registry": "Standard",
            "subjects":[
              {"id": 21}
            ],
            "organisationLinks":
              [{"id": 5023,
                "relation": "maintains",
                "fairsharingRecord": {"id": 73},
                "organisation": {"id": 2035, "name": "National Institutes of Health"},
                "grant": nil,
                "isLead": false}
              ]
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_2_m_fs_funding_organisation',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end



  def test_fail_not_correct_registry_ft_r1_2_m_fs_funding_organisation
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

    post '/test/ft_r1_2_m_fs_funding_organisation',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_indeterminate_ft_r1_2_m_fs_funding_organisation
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

    post '/test/ft_r1_2_m_fs_funding_organisation',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

end
