module FtI2MDbAdoptsTerminologies
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i2_m_db_adopts_terminologies(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'FT_I2_M_DBAdoptsTerminologies.ttl',
      testname: '',
      description: "",
      keywords: ['FAIR', 'I2'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.9114a7',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i2_m_db_adopts_terminologies',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_i2_m_db_adopts_terminologies/api'
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record
      if record['registry'] == 'Database'
        identified_rel = record['recordAssociations'].collect { |r| r if r['linkedRecord']['type'] == 'terminology_artefact'}.compact
        if identified_rel.empty?
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not adopt FAIR-supporting terminologies.'
        else
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database adopts FAIR-supporting terminologies.'
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