# frozen_string_literal: true

require_relative './test_helper'
require 'tmpdir'
require 'webmock/minitest'
require_relative '../lib/fair_test_utils'

class OraRecordCacheTest < Minitest::Test
  include FairTestUtils

  ORA_URL = 'https://ora.ox.ac.uk/objects/uuid:59dd5fb1-50b5-43c2-b935-bd9e8252140e'
  CACHE_ENVIRONMENT_VARIABLES = %w[
    CACHE_DIR
    ORA_CACHE_ENABLED
    ORA_CACHE_DIR
    ORA_CACHE_TTL
  ].freeze

  def setup
    super
    @original_environment = CACHE_ENVIRONMENT_VARIABLES.to_h { |name| [name, ENV[name]] }
    @cache_directory = Dir.mktmpdir('ora-record-cache-test')
    ENV.delete('CACHE_DIR')
    ENV['ORA_CACHE_ENABLED'] = 'true'
    ENV['ORA_CACHE_DIR'] = @cache_directory
    ENV['ORA_CACHE_TTL'] = '86400'
  end

  def teardown
    @original_environment.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
    FileUtils.remove_entry(@cache_directory) if File.exist?(@cache_directory)
    super
  end

  def test_first_request_caches_record_and_second_request_uses_it
    request = stub_jsonld(ORA_URL, 'name' => 'Example ORA record')

    first = request_jsonld(ORA_URL)
    second = request_jsonld(ORA_URL)

    assert_equal first, second
    assert_equal 'Example ORA record', second['name']
    assert_path_exists File.join(
      @cache_directory,
      'ora',
      '59dd5fb1-50b5-43c2-b935-bd9e8252140e.json'
    )
    assert_requested request, times: 1
  end

  def test_cache_paths_use_separate_service_subdirectories
    ENV['FAIRSHARING_CACHE_DIR'] = @cache_directory

    assert_equal File.join(@cache_directory, 'ora'), ora_cache_directory
    assert_equal File.join(@cache_directory, 'fairsharing'), fairsharing_cache_directory
  ensure
    ENV.delete('FAIRSHARING_CACHE_DIR')
  end

  def test_non_ora_urls_are_not_cached
    url = 'https://example.org/objects/uuid:59dd5fb1-50b5-43c2-b935-bd9e8252140e'
    request = stub_jsonld(url, 'name' => 'External record')

    2.times { assert_equal 'External record', request_jsonld(url)['name'] }

    refute_path_exists ora_cache_path(url)
    assert_requested request, times: 2
  end

  def test_non_ora_requests_preserve_existing_http_response_parsing
    url = 'https://example.org/record.jsonld'
    request = stub_request(:get, url).to_return(
      status: 503,
      body: JSON.generate('error' => 'unavailable')
    )

    assert_equal({ 'error' => 'unavailable' }, request_jsonld(url))
    assert_requested request, times: 1
  end

  def test_expired_record_is_refreshed
    request = stub_request(:get, ORA_URL).to_return(
      jsonld_response('name' => 'Old name'),
      jsonld_response('name' => 'New name')
    )

    assert_equal 'Old name', request_jsonld(ORA_URL)['name']
    cache_path = ora_cache_path(ORA_URL)
    expired_at = Time.now - ORA_CACHE_TTL - 1
    File.utime(expired_at, expired_at, cache_path)

    assert_equal 'New name', request_jsonld(ORA_URL)['name']
    assert_requested request, times: 2
  end

  def test_corrupt_record_is_replaced
    cache_path = ora_cache_path(ORA_URL)
    FileUtils.mkdir_p(File.dirname(cache_path))
    File.write(cache_path, 'not json')
    request = stub_jsonld(ORA_URL, 'name' => 'Replacement')

    assert_equal 'Replacement', request_jsonld(ORA_URL)['name']
    assert_equal 'Replacement', JSON.parse(File.read(cache_path))['name']
    assert_requested request, times: 1
  end

  def test_empty_malformed_scalar_and_http_error_responses_are_not_cached
    responses = [
      { status: 200, body: '' },
      { status: 200, body: 'not json' },
      { status: 200, body: '"plain text"' },
      { status: 503, body: '{"error":"unavailable"}' }
    ]
    request = stub_request(:get, ORA_URL).to_return(*responses)

    assert_nil request_jsonld(ORA_URL)
    assert_nil request_jsonld(ORA_URL)
    assert_equal 'plain text', request_jsonld(ORA_URL)
    assert_nil request_jsonld(ORA_URL)

    refute_path_exists ora_cache_path(ORA_URL)
    assert_requested request, times: 4
  end

  def test_nonempty_json_arrays_are_cached
    request = stub_jsonld(ORA_URL, [{ 'name' => 'Array record' }])

    2.times { assert_equal 'Array record', request_jsonld(ORA_URL).first['name'] }

    assert_path_exists ora_cache_path(ORA_URL)
    assert_requested request, times: 1
  end

  def test_request_exceptions_are_not_swallowed_or_cached
    request = stub_request(:get, ORA_URL).to_raise(Errno::ECONNRESET)

    assert_raises(Errno::ECONNRESET) { request_jsonld(ORA_URL) }

    refute_path_exists ora_cache_path(ORA_URL)
    assert_requested request, times: 1
  end

  def test_cache_can_be_disabled
    ENV['ORA_CACHE_ENABLED'] = 'false'
    request = stub_jsonld(ORA_URL, 'name' => 'Uncached')

    2.times { assert_equal 'Uncached', request_jsonld(ORA_URL)['name'] }

    refute_path_exists ora_cache_path(ORA_URL)
    assert_requested request, times: 2
  end

  def test_invalid_cache_ttl_uses_default
    ENV['ORA_CACHE_TTL'] = '60'
    assert_equal 60, ora_cache_ttl

    ENV['ORA_CACHE_TTL'] = '0'
    assert_equal ORA_CACHE_TTL, ora_cache_ttl

    ENV['ORA_CACHE_TTL'] = 'invalid'
    assert_equal ORA_CACHE_TTL, ora_cache_ttl
  end

  def test_unusual_identifiers_use_safe_hashed_paths
    unusual_url = 'https://ora.ox.ac.uk/objects/uuid:..%2Foutside%2Fcache'
    cache_path = ora_cache_path(unusual_url)

    assert_equal File.join(@cache_directory, 'ora'), File.dirname(cache_path)
    assert_match(/\Aidentifier-[a-f0-9]{64}\.json\z/, File.basename(cache_path))
    refute ora_record_url?(unusual_url)
    refute ora_record_url?('not a URL')
  end

  def test_concurrent_misses_only_request_record_once
    request = stub_request(:get, ORA_URL).to_return do
      sleep 0.05
      jsonld_response('name' => 'Concurrent record')
    end

    results = 8.times.map { Thread.new { request_jsonld(ORA_URL) } }.map(&:value)

    assert_equal ['Concurrent record'], results.map { |record| record['name'] }.uniq
    assert_requested request, times: 1
  end

  private

  def stub_jsonld(url, record)
    stub_request(:get, url).to_return(jsonld_response(record))
  end

  def jsonld_response(record)
    body = record.is_a?(String) ? record : JSON.generate(record)
    { status: 200, body: body, headers: { 'Content-Type' => 'application/ld+json' } }
  end
end
