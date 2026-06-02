module FtR12MCreatorOrcid
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_m_creator_orcid(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'ft_r1_2_m_creator_orcid',
      testname: 'FAIR Test - R1.2 - Metadata - Creator ORCIDs',
      description: 'This test evaluates whether the metadata includes at least one qualified reference to ORCID for a contributor with a ‘creator’ role. The presence of ORCIDs linked to individuals, together with the defined ‘creator’ role, constitutes a qualified provenance reference. If the record contains a creator and this creator has an ORCID ID it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.2', 'creator orcid'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.342aaa',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'fair-tests.fairsharing.org',
      basePath: 'test'
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
      )

    if record && !record.empty?
      pass = false
      identifiers = find_schema_property_value_triples(record)
      creators = find_schema_object_values(record, 'creator')
      # con_ids will contain the ID of an element that is connected to the creators.
      # These elements need to be checked if it is ORCID
      con_ids = []
      unless creators.empty?
        find_schema_object_values(creators[0], '@id').each do |id_c|
          next unless id_c.is_a?(String)

          find_all_schema_object_key_value(record, '@id', id_c).each do |c|
            schema_object_values(c, 'identifier').each do |d|
              next unless d.is_a?(String)

              con_ids << d unless d.empty?
            end
          end
        end
      end
      if identifiers.empty? || creators.empty? || con_ids.empty?
        response.score = 'fail'
        response.comments << 'This record does not contain a creator with ORCID ID.'
      else
        identifiers.each do |identifier|
          property_ids = schema_object_values(identifier, 'propertyID')
          if (property_ids & %w[ORCID]).any? && identifier.include?('@id') && con_ids.include?(identifier['@id'])
            pass = true
            break
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
    end

    response.createEvaluationResponse

  end
end
