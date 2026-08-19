# frozen_string_literal: true

module FtR13MFsDbTrustRecognition
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_3_m_fs_db_trust_recognition(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'FT_R1_3_M_FS_DBTrustRecognition.ttl',
      testname: 'FAIR Test - R1.3 - Metadata - Database demonstrates external trust or recognition',
      description: 'This test evaluates whether the database demonstrates external trust or recognition. In FAIRsharing, this corresponds to the presence of one or more certifications or community badges. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.3', 'FAIRsharing', 'external trust or recognition'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8864',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_fs_db_trust_recognition',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_fs_db_trust_recognition/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if record['registry'] == 'Database'
        if record['metadata'].include?('certifications_and_community_badges') && !record['metadata']['certifications_and_community_badges'].empty?
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database demonstrates external trust or recognition.'
        else
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not demonstrate external trust or recognition.'
        end
      else
        response.comments << 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'A matching record was not found in FAIRsharing.'
    end

    response.createEvaluationResponse
  end
end
