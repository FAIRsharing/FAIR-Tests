module FtR12MCreatorOrcid
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_m_creator_orcid(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_R1_2_M_CreatorORCID.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - Creator ORCIDs',
      description: 'This test evaluates whether the metadata includes at least one qualified reference to ORCID for a contributor with a ‘creator’ role. The presence of ORCIDs linked to individuals, together with the defined ‘creator’ role, constitutes a qualified provenance reference. If the record contains a creator and this creator has an ORCID ID it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.2', 'creator orcid'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.342aaa',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_creator_orcid',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_creator_orcid/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    # Data will look like this:
    # "creator" =>
    #   [{"@type" => "Person",
    #     "name" => "Garnett, A",
    #     "identifier" =>
    #      {"@type" => "PropertyValue",
    #       "propertyID" => "ORCID",
    #       "value" => "0000-0002-1668-1029",
    #       "url" => "https://orcid.org/0000-0002-1668-1029"}
    #    ]

    if record && !record.empty?
      creators = find_schema_object_values(record, 'creator')

      pass = creators.any? do |creator|
        next false unless creator.is_a?(Hash)

        identifiers = [
          creator['identifier'],
          creator[:identifier],
          creator['schema:identifier'],
          creator[:'schema:identifier'],
          creator['http://schema.org/identifier'],
          creator[:'http://schema.org/identifier']
        ].compact.flat_map { |identifier| identifier.is_a?(Array) ? identifier : [identifier] }

        identifiers.any? do |identifier|
          next false unless identifier.is_a?(Hash)
          next false unless schema_object_values(identifier, 'propertyID').include?('ORCID')

          schema_object_values(identifier, 'value').any? do |orcid_id|
            next false unless valid_orcid_id?(orcid_id)

            expected_url = "https://orcid.org/#{orcid_id}"
            schema_object_values(identifier, 'url').any? do |url|
              valid_url?(url) && url == expected_url
            end
          end
        end
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains a creator with ORCID ID.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain a creator with ORCID ID.'
      end
    end

    response.createEvaluationResponse

  end
end
