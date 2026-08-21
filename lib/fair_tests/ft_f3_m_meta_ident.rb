# frozen_string_literal: true
module FtF3MMetaIdent
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f3_m_meta_ident(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_F3_M_MetaIdent.ttl',
      testname: 'FAIR Test - F3 - Metadata - includes its own identifier',
      description: 'This test evaluates whether the metadata record includes its own identifier, distinct from the identifier assigned to the research object it describes. If the record contains a main identifier in their metadata it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'F3', 'identifier'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/10.25504/FAIRsharing.3df457/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f3_m_meta_ident',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f3_m_meta_ident/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
      )


    if record && !record.empty?
      identifier = find_schema_object_values(record, '@id')
      pass = identifier && !identifier.empty?

      if pass
        response.score = 'pass'
        response.comments << 'This record includes its own identifier.'
      else
        response.score = 'fail'
        response.comments << 'This record does not include its own identifier.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record matching the supplied identifier was found.'
    end

    response.createEvaluationResponse

  end
end