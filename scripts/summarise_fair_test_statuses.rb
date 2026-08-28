#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'

module FairTestStatusSummary
  REQUEST_PATTERN = %r{"POST\s+/test/([A-Za-z0-9_-]+)(?:\?\S*)?\s+HTTP/[^\"]+"\s+status=(\d{3})\b}

  module_function

  def counts_from(log)
    counts = Hash.new { |tests, test_name| tests[test_name] = Hash.new(0) }

    log.each_line do |line|
      match = REQUEST_PATTERN.match(line)
      next unless match

      test_name, status = match.captures
      counts[test_name][status] += 1
    end

    counts
  end

  def write_csv(counts, output)
    statuses = counts.values.flat_map(&:keys).uniq.sort_by(&:to_i)
    csv = CSV.new(output)

    csv << ['test_name', *statuses]
    counts.keys.sort.each do |test_name|
      csv << [test_name, *statuses.map { |status| counts[test_name][status] }]
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.first == '--help'
    puts "Usage: ruby #{__FILE__} [NGINX_LOG]"
    puts 'Writes CSV to standard output. NGINX_LOG defaults to fair-test-timing.log.'
    exit
  end

  default_log = File.expand_path('../fair-test-timing.log', __dir__)
  log_path = ARGV.first || default_log

  begin
    File.open(log_path) do |log|
      counts = FairTestStatusSummary.counts_from(log)
      FairTestStatusSummary.write_csv(counts, $stdout)
    end
  rescue SystemCallError => e
    warn "Could not read #{log_path}: #{e.message}"
    exit 1
  end
end
