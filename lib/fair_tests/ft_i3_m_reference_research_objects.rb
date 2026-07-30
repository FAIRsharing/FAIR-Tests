module FtI3MReferenceResearchObjects
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i3_m_reference_research_objects(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_I3_M_ReferenceResearchObjects.ttl',
      testname: 'FAIR Test - I3 - Metadata - Qualified References to Related Research Objects',
      description: 'This test evaluates whether the metadata retrieved upon identifier resolution contains at least one qualified, semantically defined link to another research object that provides contextual information and shows connectivity to the wider research ecosystem. Implementations of this metric should test for a qualified (labelled) relationship to a related research object, such as a publication or other research output, expressed using a defined relationship type(s) (e.g., subject of). A record will pass this metric if at least one such qualified, contextual reference to another research object is present in the metadata.',
      keywords: ['FAIR', 'I3', 'Related Research Objects'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.6cb5e5',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i3_m_reference_research_objects',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_i3_m_reference_research_objects/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      pass = false

      # TODO: Could isPartOf turn up in these records, and does it also need to be checked for?
      fieldNames = %w[subjectOf isRelatedTo]


      # data will look like:
      #"isRelatedTo" =>
      #  [{"@type" => "ScholarlyArticle",  # type could also be "CreativeWork"
      #    "name" => "name here",
      #    "url" => "https://ora.ox.ac.uk/objects/uuid:uuid-goes-here"}
      #  ]

      fieldNames.each do |fieldName|
        data = find_schema_object_values(record, fieldName)
        unless data.empty?
          data.each do |relatedTo|
            next if pass
            next unless relatedTo.is_a?(Hash) && relatedTo.include?('@type')

            pass = true if %w[ScholarlyArticle CreativeWork].include?(relatedTo['@type'].to_s.strip) &&
                           valid_url?(relatedTo['url'])
          end
        end
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains references to related research objects.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain references to related research objects.'
      end
    end

    response.createEvaluationResponse

  end
end
