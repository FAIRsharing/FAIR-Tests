# frozen_string_literal: true

module FtF4MFsHasFsRecord
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f4_m_fs_has_fs_record(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'FT_F4_M_FS_hasFSrecord.ttl',
      testname: 'FAIR Test - F4 - has FAIRsharing record',
      description: 'This test assesses whether the identifier being evaluated corresponds to a valid FAIRsharing record. Expected input is the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['ARK', 'FAIR', 'F4', 'FAIRsharing'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8375',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f4_m_fs_has_fs_record',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f4_m_fs_has_fs_record/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta
    )


    if record && !record.empty?
      response.score = 'pass'
      response.comments << 'This is a valid FAIRsharing record.'
    else
      response.score = 'fail'
      response.comments << 'No valid FAIRsharing record was found.'
    end

    response.createEvaluationResponse
  end


end
