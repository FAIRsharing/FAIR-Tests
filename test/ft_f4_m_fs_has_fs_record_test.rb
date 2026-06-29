# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f4_m_fs_has_fs_record'

class FtF4MFsHasFsRecordTest < Minitest::Test
  include ::TestHelper
  include ::FtF4MFsHasFsRecord

  def test_passes_when_identifier_resolves_to_fairsharing_record
    stub_fairsharing_record({ 'id' => '1234' })

    post '/test/ft_f4_m_fs_has_fs_record',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'This is a valid FAIRsharing record.'
  end

  def test_fails_when_identifier_is_not_a_fairsharing_record
    post '/test/ft_f4_m_fs_has_fs_record',
         params: { resource_identifier: 'https://example.org/not-a-fairsharing-record' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes last_response.body, 'No valid FAIRsharing record was found.'
  end

  def test_fails_when_fairsharing_lookup_returns_no_record
    stub_fairsharing_record(nil)

    post '/test/ft_f4_m_fs_has_fs_record',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  private

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
