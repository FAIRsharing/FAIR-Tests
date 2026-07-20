module FtF1MRidark
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f1_m_ridark(url_record)
    record = obtain_record_from_text(url_record)


    meta = {
      testid: 'FT_F1_M_RID-ARK.ttl',
      testname: 'FAIR Test - F1 - Metadata - Resolvable identifiers for database content',
      description: 'This test checks that the database requires the minting of community-relevant, publicly available globally resolvable identifiers for at least some of the content within the database being evaluated. Expected input is the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['ARK', 'FAIR', 'F1', 'RID', 'resolvable identifiers'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.6313ad',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f1_m_ridark',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f1_m_ridark/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if record['registry'] == 'Database'
        identified_rel = record['recordAssociations'].collect { |r| r if r['recordAssocLabel'] == 'implements' && r['linkedRecord']['type'] == 'identifier_schema' }.compact
        response.score = 'fail'
        identified_rel.each do |ir|
          next unless ir['linkedRecord']['metadata']['resolvable']

          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database mints resolvable identifiers.'
          break
        end
        if response.score == 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not mint resolvable identifiers.'
        end
      else
        response.score = 'fail'
        response.comments << 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record was found matching the provided identifier.'
    end

    response.createEvaluationResponse
  end

end
