# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_fs_citation_publication'

class FtR12MFsCitationPublicationTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MFsCitationPublication

  def test_pass_ft_related_citation_publication

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
            "metadata": {
              "citations": [
                {
                  "publication_id": 3232
                }
              ]
            }
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_2_m_fs_citation_publication',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
  end


  def test_fail_ft_r1_2_m_fs_citation_publication
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
            "metadata": {
              "citations": []
            }
          }
        }
      }.to_json,
      headers: headers
    )

    post '/test/ft_r1_2_m_fs_citation_publication',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end



  def test_fail_not_correct_registry_ft_r1_2_m_fs_citation_publication
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

    post '/test/ft_r1_2_m_fs_citation_publication',
         params: { resource_identifier: 'https://doi.org/10.1234/5678' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_indeterminate_ft_r1_2_m_fs_citation_publication
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

    post '/test/ft_r1_2_m_fs_citation_publication',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

end
