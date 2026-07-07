module FtR12MLinkedPublications
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_m_linked_publications(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'FT_R1_2_M_LinkedPublications.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - Linked Publications',
      description: 'This test evaluates whether the metadata includes at least one qualified reference to linked publications: where a metadata record includes at least one linked publication that explicitly supports the metadata record (rather than just providing context), this constitutes a qualified provenance reference. Where this information is present, at least one declaration is sufficient to pass this metric. The overall level of FAIRness under R1.2 increases as additional provenance dimensions are satisfied; using multiple metrics for R1.2 can help create a detailed picture of reusability. If the record is linked to an object of any of these types: ScholarlyArticle, Thesis, Book, Chapter or CreativeWork; it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.2', 'linked publications'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.653df6',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_linked_publications',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_linked_publications/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
      )

    if record && !record.empty?
      pass = false
      isRelatedTo = find_schema_object_values(record, 'isRelatedTo')
      if isRelatedTo.empty?
        response.score = 'fail'
        response.comments << 'This record does not contain a linked publication.'
      else
        isRelatedTo[0].each do |relatedTo|
          next unless relatedTo.is_a?(Hash) && relatedTo.include?('@id')

          find_all_schema_object_key_value(record, '@id', relatedTo['@id']).each do |c|
            type = schema_object_values(c, '@type')
            if (type & %w[http://schema.org/ScholarlyArticle http://schema.org/Thesis http://schema.org/Book http://schema.org/Chapter http://schema.org/CreativeWork]).any?
              pass = true
              break
            end
            break if pass
          end
          break if pass
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

    response.createEvaluationResponse

  end
end
