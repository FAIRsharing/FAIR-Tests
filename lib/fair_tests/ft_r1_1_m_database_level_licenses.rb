# frozen_string_literal: true

module FtR11MDatabaseLevelLicenses
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_1_m_database_level_licenses(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'ft_r1_1_m_database_level_licenses',
      testname: 'FAIR Metric - R1.1 - Metadata - Database-level licenses',
      description: "TBC", # TODO; please provide a suitable description
      keywords: %w[FAIR R.1.1 licenses],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/7843',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: "fair-tests.fairsharing.org",
      basePath: "test"
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
      )


    if record
      if record['registry'] == 'Database'
        licences = record['licences'] || record.dig('metadata', 'licences') || []
        if licences.empty?
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not have any licenses.'
        else
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database has at least one license.'
        end
      else
        response.score = 'fail'
        response.comments << 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'A matching record was not found in FAIRsharing.'
    end

    response.createEvaluationResponse
  end
end
