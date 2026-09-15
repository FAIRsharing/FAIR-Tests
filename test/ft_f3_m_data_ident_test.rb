# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f3_m_data_ident'

class FtF3MDataIdentTest < Minitest::Test
  include ::TestHelper
  include ::FtF3MDataIdent

  def test_passes_when_a_record_has_distribution_datadownload_with_an_id
    stub_request_jsonld(
      {
        distribution: [
          {
            '@type': 'DataDownload',
            identifier: {
              url: 'https://www.this_is_a_web.etc'
            }
          }
        ]
      }
    )

    assert_equal 'pass', run_test
  end


  def test_fails_when_record_has_no_distribution
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'A record without creators' }
    )

    assert_equal 'fail', run_test
  end

  def test_fails_when_record_has_distribution_no_datadownload
    stub_request_jsonld(
      {
        distribution: [
          {
            '@type': 'OtherType',
            identifier: {
              url: 'https://www.this_is_a_web.etc'
            }
          }
        ]
      }
    )

    assert_equal 'fail', run_test
  end

  def test_fails_when_record_has_identifier_not_url
    stub_request_jsonld(
      {
        distribution: [
          {
            '@type': 'DataDownload',
            identifier: {
              id: 'id_1'
            }
          }
        ]
      }
    )

    assert_equal 'fail', run_test
  end

  def test_fails_when_record_has_datadownload_no_id
    stub_request_jsonld(
      {
        distribution: [
          {
            '@type': 'DataDownload',
          }
        ]
      }
    )

    assert_equal 'fail', run_test
  end

  def test_is_indeterminate_when_metadata_is_unavailable
    stub_request_jsonld('')

    assert_equal 'indeterminate', run_test
  end



  def run_test
    post '/test/ft_f3_m_data_ident',
         params: { resource_identifier: ORA_RESOURCE_IDENTIFIER }.to_json,
         headers: headers

    assert last_response.ok?

    find_prov_value(parsed_response_body(last_response.body))
  end

end
