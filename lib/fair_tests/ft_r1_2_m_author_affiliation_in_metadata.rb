# frozen_string_literal: true
module FtR12MAuthorAffiliationInMetadata
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_m_author_affiliation_in_metadata(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_R1_2_M_AuthorAffiliationInMetadata.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - Author affiliation is defined in metadata',
      description: 'This test evaluates whether the metadata includes at least one qualified reference to an organisation for a contributor with a ‘creator’ role. The presence of organisations linked to individuals, together with the defined ‘creator’ role, constitutes a qualified provenance reference. If the record contains a creator and this creator has a linked organisation it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.2', 'creator affiliation'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.342aaa',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_author_affiliation_in_metadata',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_author_affiliation_in_metadata/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    # Data will look like this:
    #  "creator" =>
    #   [{"@type" => "Person",
    #     "name" => "Siefring, J",
    #     "affiliation" =>
    #      {"@type" => "Organization",
    #       "name" => "University of Oxford, GLAM, BDLSS",
    #       "identifier" =>
    #        {"@type" => "PropertyValue",
    #         "propertyID" => "ROR",
    #         "value" => "https://ror.org/052gg0110",
    #         "url" => "https://ror.org/052gg0110"}}},

    if record && !record.empty?
      creators = find_schema_object_values(record, 'creator')

      pass = creators.any? do |creator|
        next false unless creator.is_a?(Hash)

        affiliations = [
          creator['affiliation'],
          creator[:affiliation],
          creator['schema:affiliation'],
          creator[:'schema:affiliation'],
          creator['http://schema.org/affiliation'],
          creator[:'http://schema.org/affiliation']
        ].compact.flat_map { |affiliation| affiliation.is_a?(Array) ? affiliation : [affiliation] }

        affiliations.any? do |affiliation|
          next false unless affiliation.is_a?(Hash)
          next false unless schema_object_values(affiliation, '@type').include?('Organization')

          schema_object_values(affiliation, 'name').any? do |name|
            contains_meaningful_value?(name)
          end
        end
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains a creator with an organisational affiliation.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain a creator with an organisational affiliation.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record matching the supplied identifier was found.'
    end

    response.createEvaluationResponse

  end
end

