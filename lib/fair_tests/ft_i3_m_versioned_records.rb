# frozen_string_literal: true

module FtI3MVersionedRecords
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i3_m_versioned_records(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FT_I3_M_VersionedRecords.ttl',
      testname: 'FAIR Test - I3 - Metadata - Qualified References to Versioned Records',
      description: "This test evaluates whether the metadata retrieved upon identifier resolution contains at least one qualified, semantically defined link to another version of the repository record. This test search for a qualified (labelled) relationship indicating another version of the repository record (e.g. previous version, newer version, or alternative DOI version), expressed using defined relationship type(s). A repository record will pass this test if at least one item in a vector labelled 'isBasedOn' with type 'Dataset' is present in the metadata, else the test will fail. The expected input is the URL of the resource to be tested.",
      keywords: ['FAIR', 'I3', 'Versioned records'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.e10b26',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i3_m_versioned_records',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_i3_m_versioned_records/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      is_based_ons = find_schema_object_values(record, 'isBasedOn')
      pass = false
      is_based_ons.each do |is_based_on|
        next unless is_based_on.is_a?(Hash)
        next unless is_based_on.include?('@type') && is_based_on['@type'] == 'Dataset'
        next unless is_based_on.include?('url') && valid_url?(is_based_on['url'])

        pass = true
        break
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains a qualified reference to versioned records.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain a qualified references to versioned records.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record matching the provided identifier was found.'
    end

    response.createEvaluationResponse

  end
end
