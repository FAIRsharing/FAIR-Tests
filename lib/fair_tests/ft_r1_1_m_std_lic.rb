module FtR11MStdLic
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_1_m_std_lic(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_R1_1_M_StdLic.ttl',
      testname: 'FAIR Test - R1.1 - Metadata - discoverable data license in metadata',
      description: 'This test evaluates whether there is an explicit licence declaration present in the metadata retrieved upon resolution of the provided identifier. If the record contains a licence and it is a valid URL it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.1', 'license'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.714d4e',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_1_m_std_lic',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_1_m_std_lic/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if record.include?('license') && valid_url?(record['license'])
        response.score = 'pass'
        response.comments << 'This record contains discoverable data license in metadata.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain discoverable data license in metadata.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record was found matching the provided identifier.'
    end

    response.createEvaluationResponse

  end
end
