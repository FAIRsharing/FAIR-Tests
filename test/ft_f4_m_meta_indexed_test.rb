# frozen_string_literal: true

require_relative './test_helper'
require 'webmock/minitest'
require_relative '../lib/fair_tests/ft_f4_m_meta_indexed'

class FtF4MMetaIndexedTest < Minitest::Test
  include ::TestHelper
  include ::FtF4MMetaIndexed

  def test_passes_when_doi_metadata_is_found_in_datacite
    title = 'FAIRsharing record for: GenBank Nucleotide Sequence Database'
    doi = '10.25504/FAIRsharing.9kahy4'
    record = {
      'name' => title,
      'identifier' => {
        '@type' => 'PropertyValue',
        'propertyID' => 'DOI',
        'value' => doi
      }
    }
    record.define_singleton_method(:name) { self['name'] }

    stub_request(:get, "https://api.datacite.org/dois/#{doi}").
      with(headers: { 'Accept' => 'application/vnd.datacite.datacite+json' }).
      to_return(
        status: 200,
        body: {
          titles: [
            { title: title },
            { title: 'GenBank', titleType: 'AlternativeTitle' }
          ]
        }.to_json,
        headers: headers
      )

    define_singleton_method(:request_jsonld) { |_url| record }
    define_singleton_method(:search_core) { |_title| [nil, 200] }
    define_singleton_method(:search_searxng) { |_title| nil }

    response_body = ft_f4_m_meta_indexed('https://example.org/records/genbank')

    body = parsed_response_body(response_body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes response_body, 'This record was located by checking a DOI with Datacite.'
  end

  def test_passes_when_record_title_is_found_in_core
    skip 'TODO: implement test details when core is working again'
  end

  def test_reports_core_failure_when_search_returns_non_success_status
    title = 'A metadata record'
    record = { 'name' => title }
    record.define_singleton_method(:name) { self['name'] }

    define_singleton_method(:request_jsonld) { |_url| record }
    define_singleton_method(:search_core) do |searched_title|
      assert_equal title, searched_title
      [nil, 503]
    end
    define_singleton_method(:search_searxng) { |_title| [{ 'results' => [] }, 200] }

    response_body = ft_f4_m_meta_indexed('https://example.org/records/core-unavailable')

    body = parsed_response_body(response_body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes response_body, 'An attempt to search core.ac.uk failed: 503.'
    assert_includes response_body, 'No references to this identifier were found by any search attempted.'
  end

  def test_passes_when_record_title_is_found_in_searxng
    title = 'GenBank - Wikipedia'
    record = { 'name' => title }
    record.define_singleton_method(:name) { self['name'] }
    searxng_response = {
      'results' => [
        {
          'title' => 'GenBank - PMC',
          'url' => 'https://pmc.ncbi.nlm.nih.gov/articles/PMC8690257/'
        },
        {
          'title' => title,
          'url' => 'https://en.wikipedia.org/wiki/GenBank'
        }
      ]
    }

    define_singleton_method(:request_jsonld) { |_url| record }
    define_singleton_method(:search_core) { |_title| [nil, 200] }
    define_singleton_method(:search_searxng) do |searched_title|
      assert_equal title, searched_title
      [searxng_response, 200]
    end

    response_body = ft_f4_m_meta_indexed('https://example.org/records/genbank')

    body = parsed_response_body(response_body)
    assert_equal 'pass', find_prov_value(body)
    assert_includes response_body, 'This record was located by searching for its title via a general web search (SearXNG).'
  end

  def test_fails_when_no_search_finds_the_record
    title = 'An unindexed metadata record'
    doi = '10.1234/unindexed-record'
    record = {
      'name' => title,
      'identifier' => doi
    }
    record.define_singleton_method(:name) { self['name'] }

    stub_request(:get, "https://api.datacite.org/dois/#{doi}").
      with(headers: { 'Accept' => 'application/vnd.datacite.datacite+json' }).
      to_return(
        status: 200,
        body: { titles: [{ title: 'A different metadata record' }] }.to_json,
        headers: headers
      )

    define_singleton_method(:request_jsonld) { |_url| record }
    define_singleton_method(:search_core) { |_title| [nil, 200] }
    define_singleton_method(:search_searxng) { |_title| nil }

    response_body = ft_f4_m_meta_indexed('https://example.org/records/unindexed')

    body = parsed_response_body(response_body)
    assert_equal 'fail', find_prov_value(body)
    assert_includes response_body, 'No references to this identifier were found by any search attempted.'
  end

  def test_is_indeterminate_when_no_metadata_record_is_found
    define_singleton_method(:request_jsonld) { |_url| nil }
    define_singleton_method(:search_core) { |_title| flunk 'CORE should not be searched' }
    define_singleton_method(:search_searxng) { |_title| flunk 'SearXNG should not be searched' }

    response_body = ft_f4_m_meta_indexed('https://example.org/records/missing')

    body = parsed_response_body(response_body)
    assert_equal 'indeterminate', find_prov_value(body)
    assert_includes response_body, 'No record was found matching the provided identifier.'
  end
end
