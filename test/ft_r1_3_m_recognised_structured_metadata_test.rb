# frozen_string_literal: true

require 'webmock/minitest'
require_relative './test_helper'
require_relative '../lib/fair_tests/ft_r1_3_m_recognised_structured_metadata'

class FtR13MRecognisedStructuredMetadataTest < Minitest::Test
  include ::TestHelper
  include ::FtR13MRecognisedStructuredMetadata

  RESOURCE_IDENTIFIER = 'https://fairsharing.org/FAIRsharing.1414v8'

  def test_passes_when_jsonld_is_valid
    stub_request_jsonld(
      {
        '@context' => 'https://schema.org',
        '@type' => 'Dataset',
        'name' => 'A structured record'
      },
      resource_identifier: RESOURCE_IDENTIFIER
    )
    stub_request_xml('<invalid>', resource_identifier: RESOURCE_IDENTIFIER)

    assert_metric_score 'pass'
  end

  def test_passes_when_xml_is_valid
    stub_request_jsonld({}, resource_identifier: RESOURCE_IDENTIFIER)
    stub_request_xml(
      '<resource xmlns="http://datacite.org/schema/kernel-4"><titles><title>A title</title></titles></resource>',
      resource_identifier: RESOURCE_IDENTIFIER
    )

    assert_metric_score 'pass'
  end

  def test_fails_when_returned_json_and_xml_are_not_valid_structured_metadata
    stub_request_jsonld('"plain text"', resource_identifier: RESOURCE_IDENTIFIER)
    stub_request_xml('<resource>', resource_identifier: RESOURCE_IDENTIFIER)

    assert_metric_score 'fail'
  end

  def test_fails_when_json_is_empty_and_xml_is_malformed
    stub_request_jsonld({}, resource_identifier: RESOURCE_IDENTIFIER)
    stub_request_xml('<resource>', resource_identifier: RESOURCE_IDENTIFIER)

    assert_metric_score 'fail'
  end

  def test_fails_when_neither_format_returns_content
    stub_request_jsonld('', resource_identifier: RESOURCE_IDENTIFIER)
    stub_request_xml('', resource_identifier: RESOURCE_IDENTIFIER)

    assert_metric_score 'indeterminate'
  end

  private

  def assert_metric_score(expected_score)
    post '/test/ft_r1_3_m_recognised_structured_metadata',
         params: { resource_identifier: RESOURCE_IDENTIFIER }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
