module FtR12MRorIdForFunder
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_m_ror_id_for_funder(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_R1_2_M_FundROR.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - ROR ID for funder',
      description: 'This test evaluates whether the metadata includes at least one ROR ID for a funder associated with the research object. The assessment checks for structured funding references within both the landing page metadata and the central records held by DOI registration agencies (such as DataCite or Crossref). Specifically, it verifies that fields such as fundingReferences (DataCite) or funder (Crossref) are populated with at least one funder ROR ID. It checks the record’s landing page for embedded or linked structured data that can be successfully parsed against the declared community schema. If the record contains ROR identifiers it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.2', 'ror id'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8185',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_ror_id_for_funder',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_ror_id_for_funder/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    # Example data:
    # "funding" =>
    #   [{"@type" => "Grant",
    #     "identifier" => "EP/V04673X/1",
    #     "funder" =>
    #      {"@type" => "Organization",
    #       "name" => "Engineering and Physical Sciences Research Council",
    #       "identifier" =>
    #        {"@type" => "PropertyValue",
    #         "propertyID" => "ROR",
    #         "value" => "https://ror.org/0439y7842",
    #         "url" => "https://ror.org/0439y7842"}}}]

    if record && !record.empty?
      grants = find_schema_object_values(record, 'funding')
      pass = grants.any? do |grant|
        next false unless grant.is_a?(Hash)
        next false unless schema_object_values(grant, '@type').include?('Grant')

        find_schema_object_values(grant, 'funder').any? do |funder|
          next false unless funder.is_a?(Hash)
          next false unless schema_object_values(funder, 'name').any? do |name|
            contains_meaningful_value?(name)
          end

          find_schema_object_values(funder, 'identifier').any? do |identifier|
            next false unless identifier.is_a?(Hash)
            next false unless schema_object_values(identifier, 'propertyID').include?('ROR')

            values = schema_object_values(identifier, 'value')
            urls = schema_object_values(identifier, 'url')

            values.any? { |value| valid_ror_id?(value) || valid_ror_url?(value) } ||
              urls.any? { |url| valid_ror_url?(url) }
          end
        end
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains ROR identifiers.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain ROR identifiers.'
      end
    end

    response.createEvaluationResponse

  end
end
