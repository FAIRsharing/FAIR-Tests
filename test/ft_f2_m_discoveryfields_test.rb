# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f2_m_discoveryfields'

class FtF2MDiscoveryfieldsTest < Minitest::Test
  include ::TestHelper
  include ::FtF2MDiscoveryfields

=begin
  def test_is_doi_and_passes

    stub_request(:get, "https://doi.org/10.1234%2FFAIRsharing.123456").
      with(headers: datacite_headers).to_return(
      status: 200,
      body: {
        title: "This record passes"
      }.to_json,
      headers: headers
    )

    post '/test/ft_f2_m_discoveryfields',
         params: { resource_identifier: 'https://doi.org/10.1234/FAIRsharing.123456' }.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'pass'
  end
=end

  def test_is_not_doi_and_passes
    stub_request(:get, "https://doi.org/10.25504%2FFAIRsharing.9kahy4").
      with(headers: datacite_headers).to_return(
      status: 200,
      body: {}.to_json,
      headers: headers
    )

    post '/test/ft_f2_m_discoveryfields',
         params: { resource_identifier: 'https://doi.org/10.25504/FAIRsharing.9kahy4'}.to_json,
         headers: headers

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body['value'], 'pass'
  end

  # TODO: Add tests for fail, intermediate, and all for content negotiation


end
