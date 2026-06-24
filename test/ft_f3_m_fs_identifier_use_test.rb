# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f3_m_fs_identifier_use'

class FtF3MFsIdentifierUseTest < Minitest::Test
  include ::TestHelper
  include ::FtF3MFsIdentifierUse

  def test_passes_with_valid_doi_and_resolvable_homepage
    stub_fairsharing_record(record_with_metadata(
                              'doi' => '10.25504/FAIRsharing.123456',
                              'homepage' => 'https://example.org'
                            ))
    stub_homepage(status: 200)

    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'This record contains a valid FAIRsharing DOI.'
  end

  def test_passes_with_missing_doi_when_homepage_resolves
    stub_fairsharing_record(record_with_metadata('homepage' => 'https://example.org'))
    stub_homepage(status: 200)

    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'This record does not contain a FAIRsharing DOI.'
  end

  def test_passes_with_invalid_doi_when_homepage_resolves
    stub_fairsharing_record(record_with_metadata(
                              'doi' => 'not a doi',
                              'homepage' => 'https://example.org'
                            ))
    stub_homepage(status: 200)

    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes last_response.body, 'This record contains an invalid FAIRsharing DOI.'
  end

  def test_fails_with_missing_homepage
    stub_fairsharing_record(record_with_metadata('doi' => '10.25504/FAIRsharing.123456'))

    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_with_invalid_homepage
    stub_fairsharing_record(record_with_metadata(
                              'doi' => '10.25504/FAIRsharing.123456',
                              'homepage' => 'not a url'
                            ))

    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_homepage_does_not_resolve
    stub_fairsharing_record(record_with_metadata(
                              'doi' => '10.25504/FAIRsharing.123456',
                              'homepage' => 'https://example.org'
                            ))
    stub_homepage(status: 404)

    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_fails_when_homepage_head_raises
    stub_fairsharing_record(record_with_metadata(
                              'doi' => '10.25504/FAIRsharing.123456',
                              'homepage' => 'https://example.org'
                            ))
    stub_homepage(error: Net::ReadTimeout.new('execution expired'))

    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://fairsharing.org/1234' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'fail', find_prov_value(body)
  end

  def test_is_indeterminate_when_record_cannot_be_obtained
    post '/test/ft_f3_m_fs_identifier_use',
         params: { resource_identifier: 'https://example.org/not-a-fairsharing-record' }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal 'indeterminate', find_prov_value(body)
  end

  private

  def record_with_metadata(metadata)
    {
      'id' => '1234',
      'metadata' => metadata
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

  def stub_homepage(status: nil, error: nil)
    request = stub_request(:head, 'https://example.org')
    error ? request.to_raise(error) : request.to_return(status: status, body: '', headers: {})
  end

  def graphql_query(request)
    JSON.parse(request.body)['query']
  rescue JSON::ParserError
    ''
  end
end
