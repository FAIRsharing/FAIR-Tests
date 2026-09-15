# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f3_m_meta_ident'

class FtF3MMetaIdentTest < Minitest::Test
  include ::TestHelper
  include ::FtF3MMetaIdent

  def test_passes_when_a_record_has_an_id
    stub_request_jsonld(
      {
        '@id': 'dsadwqe23'
      }
    )

    assert_equal 'pass', run_test
  end


  def test_fails_when_record_has_no_id
    stub_request_jsonld(
      {
        '@no_id': 'dsadwqe23'
      }
    )

    assert_equal 'fail', run_test
  end


  def test_is_indeterminate_when_metadata_is_unavailable
    stub_request_jsonld('')

    assert_equal 'indeterminate', run_test
  end



  def run_test
    post '/test/ft_f3_m_meta_ident',
         params: { resource_identifier: ORA_RESOURCE_IDENTIFIER }.to_json,
         headers: headers

    assert last_response.ok?

    find_prov_value(parsed_response_body(last_response.body))
  end

end
