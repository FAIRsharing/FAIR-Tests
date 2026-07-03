module FtI3MReferenceResearchObjects
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i3_m_reference_research_objects(url_record)
    record = metadata_harvesting(url_record)

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

      # TODO: Could isPartOf turn up in these records, and does it also need to be checked for?
      fieldName = 'isRelatedTo'

      data = find_schema_object_values(record, fieldName)

      if data.empty?
        response.score = 'fail'
        response.comments << 'This record does not contain references to related research objects.'
      else
        # data will look like:
        #  [[{"@id" => "_:g465680"}, {"@id" => "_:g464640"}]]
        #  pass should be true if there is at least one of the related elements
        # containing type and url
        #TODO this part can change if the harvester returns the URL field in other place
        data[0].each do |relatedTo|
          next unless relatedTo.is_a?(Hash) && relatedTo.include?('@id')

          find_all_schema_object_key_value(record, '@id', relatedTo['@id']).each do |c|
            # @url should be a valid URL already as the linked data gem will discard it if it is not.
            # So, its format has not been checked again here, only its presence.
            pass = true if c.is_a?(Hash) && c['@type'].to_s.strip != '' && c['@url'].to_s.strip != ''
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
