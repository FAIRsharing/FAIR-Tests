#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

module LiveOraTest
  DEFAULT_ORA_IDENTIFIER = 'https://ora.ox.ac.uk/objects/uuid:ad7da8fc-cd8e-4637-8b7c-99498436dbaa'
  TEST_DIRECTORY = File.expand_path('../lib/fair_tests', __dir__)
  TEST_NAMES = %w[
    ft_f1_m_metadata_id_persistent
    ft_f1_m_metadata_id_resolvable
    ft_f1_m_metadata_id_unique
  ].freeze

  module_function

  def test_cases
    TEST_NAMES.map do |test_name|
      file = File.join(TEST_DIRECTORY, "#{test_name}.rb")
      require file

      module_name = File.basename(file, '.rb').split('_').map(&:capitalize).join
      test_module = Object.const_get(module_name)

      [test_name.to_sym, test_module]
    end
  end

  def score_from(response)
    payload = JSON.parse(response)
    result = Array(payload['@graph']).find do |node|
      Array(node['@type']).include?('ftr:TestResult')
    end
    score = result&.dig('prov:value', '@value')

    raise 'The test response did not contain a result score' if score.nil?

    score.to_s.downcase
  end

  def run(identifier, output: $stdout)
    cases = test_cases
    failures = 0

    output.puts "ORA resource: #{identifier}"
    output.puts "Running #{cases.length} ORA F1 FAIR tests..."

    cases.each do |method_name, test_module|
      runner = Object.new.extend(test_module)
      score = score_from(runner.public_send(method_name, identifier))

      if score == 'pass'
        output.puts "PASS #{method_name}"
      else
        failures += 1
        output.puts "FAIL #{method_name} (score: #{score})"
      end
    rescue StandardError => e
      failures += 1
      output.puts "FAIL #{method_name} (#{e.class}: #{e.message})"
    end

    passes = cases.length - failures
    output.puts
    output.puts "Summary: #{passes} passed, #{failures} failed, #{cases.length} total"

    failures
  end
end

if $PROGRAM_NAME == __FILE__
  $stdout.sync = true

  if ARGV.first == '--help'
    puts "Usage: bundle exec ruby #{__FILE__} [ORA_RESOURCE_IDENTIFIER]"
    exit
  end

  identifier = ARGV.first || LiveOraTest::DEFAULT_ORA_IDENTIFIER
  exit(LiveOraTest.run(identifier).zero? ? 0 : 1)
end
