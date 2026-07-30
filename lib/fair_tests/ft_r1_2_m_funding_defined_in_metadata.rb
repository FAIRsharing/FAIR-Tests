# frozen_string_literal: true
module FtR12MFundingDefinedInMetadata
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_m_funding_defined_in_metadata(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_R1_2_M_FundingDefinedInMetadata.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - Funding information is defined in metadata',
      description: 'This test evaluates whether the metadata includes explicit details regarding the funding associated with the research object. Specifically, it checks for at least one funder entry within the funding data structure. Expected input is the identifier of the record to be tested.',
      keywords: ['FAIR', 'R1.2', 'funding'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/7496',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_funding_defined_in_metadata',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_funding_defined_in_metadata/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    # Expected data structure:
    # "funding": [
    #     {
    #       "@type": "Grant",
    #       "identifier": "EP/V04673X/1",
    #       "funder": {
    #         "@type": "Organization",
    #         "name": "Engineering and Physical Sciences Research Council",
    #         "identifier": {
    #           "@type": "PropertyValue",
    #           "propertyID": "ROR",
    #           "value": "https://ror.org/0439y7842",
    #           "url": "https://ror.org/0439y7842"
    #         }
    #       }
    #     }
    #   ]

    if record && !record.empty?
      if funding_defined?(record)
        response.score = 'pass'
        response.comments << 'This record contains funding information.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain funding information.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No metadata was found for the provided identifier.'
    end

    response.createEvaluationResponse
  end

end
