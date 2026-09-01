# frozen_string_literal: true

require_relative './test_helper'
require 'tmpdir'
require 'webmock/minitest'
require_relative '../lib/fair_test_utils'

class FairsharingRecordCacheTest < Minitest::Test
  include FairTestUtils

  CACHE_ENVIRONMENT_VARIABLES = %w[
    FAIRSHARING_CACHE_ENABLED
    FAIRSHARING_CACHE_DIR
    FAIRSHARING_CACHE_TTL
  ].freeze

  def setup
    super
    @original_environment = CACHE_ENVIRONMENT_VARIABLES.to_h { |name| [name, ENV[name]] }
    @cache_directory = Dir.mktmpdir('fairsharing-record-cache-test')
    ENV['FAIRSHARING_CACHE_ENABLED'] = 'true'
    ENV['FAIRSHARING_CACHE_DIR'] = @cache_directory
    ENV['FAIRSHARING_CACHE_TTL'] = '86400'
  end

  def teardown
    @original_environment.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
    FileUtils.remove_entry(@cache_directory) if File.exist?(@cache_directory)
    super
  end

  def test_first_request_caches_record_and_equivalent_identifier_uses_it
    request = stub_fairsharing_record('id' => 'abc123', 'name' => 'Example record')

    first = get_fairsharing_record('10.25504/FAIRsharing.ABC123')
    second = get_fairsharing_record('https://fairsharing.org/FAIRsharing.abc123')

    assert_equal first, second
    assert_equal 'Example record', second['name']
    assert_path_exists File.join(@cache_directory, 'fairsharing', 'fairsharing.abc123.json')
    assert_requested request, times: 1
  end

  def test_normalizes_numeric_and_unsafe_identifiers_to_safe_cache_paths
    assert_equal '123.json', File.basename(fairsharing_cache_path(123))
    assert_equal '123.json', File.basename(fairsharing_cache_path('https://fairsharing.org/123/'))
    assert_equal 'fairsharing.abc123.json',
                 File.basename(fairsharing_cache_path('https://doi.org/10.25504%2FFAIRsharing.ABC123'))

    unsafe_path = fairsharing_cache_path('../../outside/cache')
    assert_equal File.join(@cache_directory, 'fairsharing'), File.dirname(unsafe_path)
    assert_match(/\Aidentifier-[a-f0-9]{64}\.json\z/, File.basename(unsafe_path))
  end

  def test_expired_record_is_refreshed
    request = stub_fairsharing_responses(
      successful_response('id' => '123', 'name' => 'Old name'),
      successful_response('id' => '123', 'name' => 'New name')
    )

    assert_equal 'Old name', get_fairsharing_record(123)['name']
    cache_path = fairsharing_cache_path(123)
    expired_at = Time.now - FAIRSHARING_CACHE_TTL - 1
    File.utime(expired_at, expired_at, cache_path)

    assert_equal 'New name', get_fairsharing_record(123)['name']
    assert_requested request, times: 2
  end

  def test_corrupt_record_is_replaced
    cache_path = fairsharing_cache_path('FAIRsharing.abc123')
    FileUtils.mkdir_p(File.dirname(cache_path))
    File.write(cache_path, 'not json')
    request = stub_fairsharing_record('id' => 'abc123', 'name' => 'Replacement')

    assert_equal 'Replacement', get_fairsharing_record('FAIRsharing.abc123')['name']

    assert_equal 'Replacement', JSON.parse(File.read(cache_path))['name']
    assert_requested request, times: 1
  end

  def test_api_errors_are_not_cached
    request = stub_request(:post, ENV.fetch('FAIRSHARING_API_URL')).to_return(status: 503)

    2.times do
      result = get_fairsharing_record('FAIRsharing.unavailable')
      assert_match(/Error getting record from FAIRsharing API: 503/, result[:message])
    end

    refute_path_exists fairsharing_cache_path('FAIRsharing.unavailable')
    assert_requested request, times: 2
  end

  def test_malformed_api_responses_are_not_cached
    request = stub_fairsharing_responses(
      { status: 200, body: 'not json' },
      { status: 200, body: 'still not json' }
    )

    2.times { assert_equal({}, get_fairsharing_record('FAIRsharing.malformed')) }

    refute_path_exists fairsharing_cache_path('FAIRsharing.malformed')
    assert_requested request, times: 2
  end

  def test_api_exceptions_are_not_swallowed_or_cached
    request = stub_request(:post, ENV.fetch('FAIRSHARING_API_URL')).to_raise(Errno::ECONNRESET)

    assert_raises(Errno::ECONNRESET) do
      get_fairsharing_record('FAIRsharing.connection-error')
    end

    refute_path_exists fairsharing_cache_path('FAIRsharing.connection-error')
    assert_requested request, times: 1
  end

  def test_failed_refresh_does_not_overwrite_expired_record
    cache_path = fairsharing_cache_path(123)
    FileUtils.mkdir_p(File.dirname(cache_path))
    File.write(cache_path, JSON.generate('id' => '123', 'name' => 'Stale record'))
    expired_at = Time.now - FAIRSHARING_CACHE_TTL - 1
    File.utime(expired_at, expired_at, cache_path)
    stub_request(:post, ENV.fetch('FAIRSHARING_API_URL')).to_return(status: 503)

    result = get_fairsharing_record(123)

    assert_match(/Error getting record from FAIRsharing API: 503/, result[:message])
    assert_equal 'Stale record', JSON.parse(File.read(cache_path))['name']
  end

  def test_cache_can_be_disabled
    ENV['FAIRSHARING_CACHE_ENABLED'] = 'false'
    request = stub_fairsharing_record('id' => '123')

    2.times { assert_equal '123', get_fairsharing_record(123)['id'] }

    refute_path_exists fairsharing_cache_path(123)
    assert_requested request, times: 2
  end

  def test_invalid_cache_ttl_uses_default
    ENV['FAIRSHARING_CACHE_TTL'] = '60'
    assert_equal 60, fairsharing_cache_ttl

    ENV['FAIRSHARING_CACHE_TTL'] = '0'
    assert_equal FAIRSHARING_CACHE_TTL, fairsharing_cache_ttl

    ENV['FAIRSHARING_CACHE_TTL'] = 'invalid'
    assert_equal FAIRSHARING_CACHE_TTL, fairsharing_cache_ttl
  end

  def test_cache_filesystem_failures_fall_back_to_api
    unusable_path = File.join(@cache_directory, 'not-a-directory')
    File.write(unusable_path, 'file')
    ENV['FAIRSHARING_CACHE_DIR'] = File.join(unusable_path, 'cache')
    request = stub_fairsharing_record('id' => '123')

    assert_equal '123', get_fairsharing_record(123)['id']

    assert_requested request, times: 1
  end

  def test_cache_write_errors_do_not_hide_retrieved_record
    invalid_path = File.join(@cache_directory, 'parent-file')
    File.write(invalid_path, 'file')

    write_fairsharing_cache(File.join(invalid_path, '123.json'), 'id' => '123')

    refute_path_exists File.join(invalid_path, '123.json')
  end

  def test_lock_errors_fall_back_to_api
    request = stub_fairsharing_record('id' => '123')

    result = with_failing_file_lock { get_fairsharing_record(123) }

    assert_equal '123', result['id']
    assert_requested request, times: 1
  end

  def test_concurrent_misses_only_call_api_once
    request = stub_request(:post, ENV.fetch('FAIRSHARING_API_URL')).to_return do
      sleep 0.05
      successful_response('id' => '123', 'name' => 'Concurrent record')
    end

    results = 8.times.map do
      Thread.new { get_fairsharing_record(123) }
    end.map(&:value)

    assert_equal ['Concurrent record'], results.map { |record| record['name'] }.uniq
    assert_requested request, times: 1
  end

  private

  def stub_fairsharing_record(record)
    stub_fairsharing_responses(successful_response(record))
  end

  def stub_fairsharing_responses(*responses)
    stub_request(:post, ENV.fetch('FAIRSHARING_API_URL')).to_return(*responses)
  end

  def successful_response(record)
    {
      status: 200,
      body: { 'data' => { 'fairsharingRecord' => record } }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  end

  def with_failing_file_lock
    file_singleton = File.singleton_class
    original_method = :__original_open_for_fairsharing_cache_test
    file_singleton.alias_method original_method, :open
    file_singleton.define_method(:open) do |path, *args, **kwargs, &block|
      next public_send(original_method, path, *args, **kwargs, &block) unless path.to_s.end_with?('.lock')

      Object.new.tap do |lock_file|
        lock_file.define_singleton_method(:flock) { |_operation| raise Errno::EIO, 'lock failed' }
        lock_file.define_singleton_method(:close) {}
      end
    end

    yield
  ensure
    if defined?(file_singleton) && file_singleton.method_defined?(original_method)
      file_singleton.remove_method :open if file_singleton.method_defined?(:open)
      file_singleton.alias_method :open, original_method
      file_singleton.remove_method original_method
    end
  end
end
