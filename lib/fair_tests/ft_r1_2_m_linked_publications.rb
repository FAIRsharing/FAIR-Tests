module FtR12MLinkedPublications
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_m_linked_publications(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'ft_r1_2_m_ror_id_for_funder',
      testname: 'FAIR Test - R1.2 - Metadata - Linked Publications',
      description: 'This test evaluates whether the metadata includes at least one qualified reference to linked publications: where a metadata record includes at least one linked publication that explicitly supports the metadata record (rather than just providing context), this constitutes a qualified provenance reference. Where this information is present, at least one declaration is sufficient to pass this metric. The overall level of FAIRness under R1.2 increases as additional provenance dimensions are satisfied; using multiple metrics for R1.2 can help create a detailed picture of reusability. If the record is linked to an object of any of these types: ScholarlyArticle, Thesis, Book, Chapter or CreativeWork; it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.2', 'linked publications'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.653df6',
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
      isRelatedTo = find_schema_object_values(record, 'isRelatedTo')
      identifiers = find_schema_property_value_triples(record)
      if isRelatedTo.empty? || identifiers.empty?
        response.score = 'fail'
        response.comments << 'This record does not contain a linked publication.'
      else
        val_ids = []
        isRelatedTo[0].each do |realtedTo|
          next unless realtedTo.is_a?(Hash) && realtedTo.include?('@id')

          val_ids << realtedTo['@id']
        end
        unless val_ids.empty?

          identifiers.each do |identifier|
            type = schema_object_values(identifier, '@type')

            if (identifier.is_a?(Hash) && type & %w[ScholarlyArticle, Thesis, Book, Chapter, CreativeWork]).any? && identifier.include?('@id') && val_ids.include?(identifier['@id'])
                pass = true
                break
              end
            end


          end
        end

        if pass
          response.score = 'pass'
          response.comments << 'This record contains a linked publication.'
        else
          response.score = 'fail'
          response.comments << 'This record does not contain a linked publication.'
        end
      end
    end

    response.createEvaluationResponse

  end
end
