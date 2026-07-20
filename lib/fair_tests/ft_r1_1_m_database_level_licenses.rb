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
      testid: 'FT_R1_1_M_DatabaseLevelLicenses.ttl',
      testname: 'FAIR Test - R1.1 - Metadata - Database-level licenses',
      description: "R1.1 requires that metadata be released with a clear and accessible data usage licence. The purpose of this principle is to ensure that reuse conditions are explicitly stated and legally unambiguous. This test evaluates whether there is at least one licence declared at the database level in the FAIRsharing registry record associated with the identifier under evaluation. Expected input is the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.",
      keywords: %w[FAIR R.1.1 licenses],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/7843',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_1_m_database_level_licenses',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_1_m_database_level_licenses/api',
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
