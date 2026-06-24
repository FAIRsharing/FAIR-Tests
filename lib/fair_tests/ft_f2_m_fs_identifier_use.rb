# frozen_string_literal: true

module FtF2MFsIdentifierUse
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f2_m_fs_identifier_use(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'FT_F2_M_FsIdentifierUse.ttl',
      testname: 'FAIR Test - F3 - resource identifiers in FAIRsharing metadata',
      description: 'This test assesses whether the FAIRsharing record under evaluation contains both a FAIRsharing identifier (DOI or URL) and a homepage URL for the resource it describes. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['ARK', 'FAIR', 'F1', 'FAIRsharing', 'GUID'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8372',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f2_m_fs_identifier_use',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f2_m_fs_identifier_use/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?

    end

    response.createEvaluationResponse
  end
end
