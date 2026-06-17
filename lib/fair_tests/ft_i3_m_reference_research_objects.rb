module FtI3MReferenceResearchObjects
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i3_m_reference_research_objects(url_record)
    ora_format = false
    if url_record.include? 'ora.ox.ac.uk'
      record = request_jsonld(url_record)
      ora_format = true
    else
      record = metadata_harvesting(url_record)
    end

    meta = {
      testid: 'FT_I3_M_ReferenceResearchObjects.ttl',
      testname: 'FAIR Test - I3 - Metadata - Qualified References to Related Research Objects',
      description: 'This test evaluates whether the metadata retrieved upon identifier resolution contains at least one qualified, semantically defined link to another research object that provides contextual information and shows connectivity to the wider research ecosystem. Implementations of this metric should test for a qualified (labelled) relationship to a related research object, such as a publication or other research output, expressed using a defined relationship type(s) (e.g., related to). A record will pass this metric if at least one such qualified, contextual reference to another research object is present in the metadata.',
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

      if ora_format
        fieldName = 'isPartOf'
      else
        fieldName = 'isRelatedTo'
      end

      data = find_schema_object_values(record, fieldName)

      if data.empty?
        response.score = 'fail'
        response.comments << 'This record does not contain references to related research objects.'
      else
        if ora_format
          # data will look like:
          # [[{"@type" => "CreativeWork",
          #    "name" => "The effect of ambient and injection pressure on droplet size of ammonia sprays in a constant volume chamber",
          #    "url" => "/objects/uuid:7f161a34-1d6c-40aa-9539-847a4ff00f44"}]]
          # pass should be true if there is at least one @type with a url value.
          pass = data.flatten.any? do |related_object|
            related_object.is_a?(Hash) &&
              related_object['@type'].to_s.strip != '' &&
              related_object['url'].to_s.strip != ''
          end
        else
          # data will look like:
          #  [[{"@id" => "_:g465680"}, {"@id" => "_:g464640"}]]
          #  pass should be true if there is at least one @id with a value.
          pass = data.flatten.any? do |related_object|
            related_object.is_a?(Hash) && related_object['@id'].to_s.strip != ''
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
