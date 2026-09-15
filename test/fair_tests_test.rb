# frozen_string_literal: true

require_relative './test_helper'

class FairTestsTest < Minitest::Test
  include TestHelper

  class CapturingLogger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def error(message)
      messages << message
    end
  end

  def setup
    @original_logger = FairTests.settings.test_failure_logger
    @logger = CapturingLogger.new
    FairTests.set :test_failure_logger, @logger
  end

  def teardown
    FairTests.set :test_failure_logger, @original_logger
  end

  def test_failure_log_formatter_writes_one_json_record_per_line
    message = { event: 'fair_test_exception' }.to_json

    formatted = FairTests::TEST_FAILURE_LOGGER.formatter.call(
      Logger::ERROR,
      Time.now,
      nil,
      message
    )

    assert_equal "#{message}\n", formatted
  end

  def test_logs_test_name_and_resource_identifier_then_reraises
    resource_identifier = %w[not a URL]

    error = assert_raises(NoMethodError) do
      post_json({ resource_identifier: resource_identifier }.to_json)
    end

    log_entry = JSON.parse(@logger.messages.last)
    assert_equal resource_identifier, log_entry['resource_identifier']
    assert_exception_log(log_entry, error)
  end

  def test_logs_invalid_json_with_no_resource_identifier
    error = assert_raises(JSON::ParserError) do
      post_json('{invalid')
    end

    log_entry = JSON.parse(@logger.messages.last)
    assert_nil log_entry['resource_identifier']
    assert_exception_log(log_entry, error)
  end

  private

  def post_json(body)
    Rack::MockRequest.new(app).post(
      '/test/ft_a1_1_m_https_retrieval_protocol',
      'CONTENT_TYPE' => 'application/json',
      input: body
    )
  end

  def assert_exception_log(log_entry, error)
    expected = {
      'event' => 'fair_test_exception',
      'test_name' => 'ft_a1_1_m_https_retrieval_protocol',
      'error_class' => error.class.name,
      'error_message' => error.message
    }
    assert_equal expected, log_entry.slice(*expected.keys)
    assert_kind_of Array, log_entry['backtrace']
    refute_empty log_entry['backtrace']
    assert_match(/\A\d{4}-\d{2}-\d{2}T/, log_entry['timestamp'])
  end
end
