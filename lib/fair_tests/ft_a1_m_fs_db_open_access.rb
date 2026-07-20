# frozen_string_literal: true

module FtA1MFsDbOpenAccess
  require_relative '../fair_test_utils'
  include FairTestUtils

  OPEN_ACCESS_CONDITIONS = ['open', 'partially open'].freeze

  def ft_a1_m_fs_db_open_access(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'FT_A1_M_FS_dbOpenAccess.ttl',
      testname: 'FAIR Test - A1 - Metadata - database open access',
      description: 'This test assesses whether the FAIRsharing database record has its Data Access Condition set to Open or Partially Open. Expected input is the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['ARK', 'FAIR', 'A1', 'FAIRsharing', 'database', 'open access'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8381',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_a1_m_fs_db_open_access',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_a1_m_fs_db_open_access/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta
    )

    if record && !record.empty?
      if record['registry'] == 'Database'
        if open_access_condition?(record.dig('metadata', 'data_access_condition'))
          response.score = 'pass'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database has open or partially open data access."
        else
          response.score = 'fail'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database does not have open or partially open data access."
        end
      else
        response.score = 'fail'
        response.comments << "The record exists in FAIRsharing (https://fairsharing.org/#{record['id']}) but it is not a database."
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record was found matching the provided identifier.'
    end

    response.createEvaluationResponse
  end

  private

  def open_access_condition?(condition)
    value = condition['type']
    OPEN_ACCESS_CONDITIONS.include?(value.to_s.strip.downcase)
  end
end
