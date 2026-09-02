# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_1_m_std_lic'

class FtR11MStdLicTest < Minitest::Test
  include ::TestHelper
  include ::FtR11MStdLic

  def test_passes_when_a_record_has_a_valid_license
    stub_request_jsonld(
      {
        'license': 'https://www.opendatacommons.org/licenses/pddl/1-0/index.html'
      }
    )

    assert_equal 'pass', run_test
  end


  def test_fails_when_record_has_no_license
    stub_request_jsonld(
      {
        '@no_id': 'dsadwqe23'
      }
    )

    assert_equal 'fail', run_test
  end

  def test_fails_when_record_has_no_valid_license
    stub_request_jsonld(
      {
        'license': 'opendatacommons.org/licenses/pddl/1-0/index'
      }
    )

    assert_equal 'fail', run_test
  end


  def test_is_indeterminate_when_metadata_is_unavailable
    stub_request_jsonld('')

    assert_equal 'indeterminate', run_test
  end



  def run_test
    post '/test/ft_r1_1_m_std_lic',
         params: { resource_identifier: ORA_RESOURCE_IDENTIFIER }.to_json,
         headers: headers

    assert last_response.ok?

    find_prov_value(parsed_response_body(last_response.body))
  end

end
