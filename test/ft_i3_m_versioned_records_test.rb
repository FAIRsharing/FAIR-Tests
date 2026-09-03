# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_i3_m_versioned_records'

class FtI3MVersionedRecordsTest < Minitest::Test
  include ::TestHelper
  include ::FtI3MVersionedRecords

  RESOURCE_IDENTIFIER = 'https://example.org/records/abc123'

  def test_passes_when_is_based_on_valid
    stub_is_based_on(
      [
        {
          '@type' => 'Dataset',
          'name' => 'Assessing adherence to the UK Governments sugar, salt, and calorie reduction targets by the highest-grossing restaurants menus in 2024: dataset to support a cross-sectional study',
          'url' => 'https://doi.org/10.5287/ora-6raddkr21dasdasdg91',
          'dateCreated' => '2025-07-01T12:28:31+01:00'
        }
      ]
    )

    assert_metric_score 'pass'
  end

  def test_passes_when_any_is_based_on_valid
    stub_is_based_on(
      [
        {
          '@type' => 'Dataset',
          'name' => 'Assessing adherence to the UK Governments sugar, salt, and calorie reduction targets by the highest-grossing restaurants menus in 2024: dataset to support a cross-sectional study',
          'url' => 'fewfewf',
          'dateCreated' => '2025-07-01T12:28:31+01:00'
        },
        {
          '@type' => 'Dataset',
          'name' => 'Assessing adherence to the UK Governments sugar, salt, and calorie reduction targets by the highest-grossing restaurants menus in 2024: dataset to support a cross-sectional study',
          'url' => 'https://doi.org/10.5287/ora-6raddkr21dasdasdg91',
          'dateCreated' => '2025-07-01T12:28:31+01:00'
        }
      ]
    )

    assert_metric_score 'pass'
  end


  def test_fails_when_is_based_on_url_is_not_well_formed
    stub_is_based_on(
      [
        {
          '@type' => 'Dataset',
          'name' => 'Assessing adherence to the UK Governments sugar, salt, and calorie reduction targets by the highest-grossing restaurants menus in 2024: dataset to support a cross-sectional study',
          'url' => 'rgergergrehttps://doi.ddkr21dasdasdg9-1',
          'dateCreated' => '2025-07-01T12:28:31+01:00'
        }
      ]
    )

    assert_metric_score 'fail'
  end


  def test_fails_when_is_based_on_url_is_not_type_data
    stub_is_based_on(
      [
        {
          '@type' => 'WebSite',
          'name' => 'Assessing adherence to the UK Governments sugar, salt, and calorie reduction targets by the highest-grossing restaurants menus in 2024: dataset to support a cross-sectional study',
          'url' => 'https://doi.org/10.5287/ora-6raddkr21dasdasdg91',
          'dateCreated' => '2025-07-01T12:28:31+01:00'
        }
      ]
      )

    assert_metric_score 'fail'
  end


  def test_fails_when_is_based_on_field_is_missing
    stub_request_jsonld(
      { '@type' => 'Dataset', 'name' => 'A record without language metadata' },
      resource_identifier: RESOURCE_IDENTIFIER
    )

    assert_metric_score 'fail'
  end

  def test_is_indeterminate_when_no_record_is_found
    stub_request_jsonld({}, resource_identifier: RESOURCE_IDENTIFIER)

    assert_metric_score 'indeterminate'
  end


  private

  def stub_is_based_on(is_based_on)
    stub_request_jsonld(
      {
        '@type' => 'Dataset',
        'isBasedOn' => is_based_on
      },
      resource_identifier: RESOURCE_IDENTIFIER
    )
  end

  def assert_metric_score(expected_score)
    post '/test/ft_i3_m_versioned_records',
         params: { resource_identifier: RESOURCE_IDENTIFIER }.to_json,
         headers: headers

    assert last_response.ok?

    body = parsed_response_body(last_response.body)
    assert_equal expected_score, find_prov_value(body)
  end
end
