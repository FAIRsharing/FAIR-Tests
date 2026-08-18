# frozen_string_literal: true
require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_r1_2_m_funding_defined_in_metadata'

class FtR12MFundingDefinedInMetadataTest < Minitest::Test
  include ::TestHelper
  include ::FtR12MFundingDefinedInMetadata

  def test_passes_when_record_contains_funding_data
    stub_request_jsonld(
      {
        funding: [
          {
            '@type': 'Grant',
            identifier: 'EP/V04673X/1',
            funder: {
              '@type': 'Organization',
              name: 'Engineering and Physical Sciences Research Council'
            }
          }
        ]
      }
    )

    assert_equal 'pass', run_test
  end

  def test_fails_when_funding_is_absent
    stub_request_jsonld({ name: 'An unfunded research object' })

    assert_equal 'fail', run_test
  end

  def test_fails_when_funding_contains_no_data
    stub_request_jsonld({ funding: [{ funder: { name: ' ' } }] })

    assert_equal 'fail', run_test
  end

  def test_is_indeterminate_when_metadata_is_unavailable
    stub_request_jsonld('')

    assert_equal 'indeterminate', run_test
  end

  private

  def run_test
    post '/test/ft_r1_2_m_funding_defined_in_metadata',
         params: { resource_identifier: ORA_RESOURCE_IDENTIFIER }.to_json,
         headers: headers

    assert last_response.ok?

    find_prov_value(parsed_response_body(last_response.body))
  end
end
