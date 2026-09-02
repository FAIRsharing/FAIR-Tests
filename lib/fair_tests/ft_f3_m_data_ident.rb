# frozen_string_literal: true
module FtF3MDataIdent
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f3_m_data_ident(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_F3_M_DataIdent.ttl',
      testname: 'FAIR Test - F3 - Metadata -  include the identifier of the data it describes',
      description: 'This test evaluates whether the metadata record explicitly includes the identifier of the research object(s) it describes. If the record contains a distribution object of type DataDownload and it contains an identifier, this test will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'F3', 'data identifier'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/10.25504/FAIRsharing.0a2061/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f3_m_data_ident',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f3_m_data_ident/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
      )


    if record && !record.empty?
      distributions = find_schema_object_values(record, 'distribution')
      pass = false
      distributions.each do |distribution|
        next unless distribution.is_a?(Hash)
        next unless schema_object_values(distribution, '@type').include?('DataDownload')

        if distribution.include?('identifier') && valid_url?(distribution['identifier'])
          pass = true
          break
        end
      end
      if pass
        response.score = 'pass'
        response.comments << 'This record includes an identifier of the data it describes.'
      else
        response.score = 'fail'
        response.comments << 'This record does not include the identifier of the data it describes.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record matching the supplied identifier was found.'
    end

    response.createEvaluationResponse

  end
end
