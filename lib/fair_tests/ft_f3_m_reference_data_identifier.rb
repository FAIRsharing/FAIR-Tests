module FtF3MReferenceDataIdentifier
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f3_m_reference_data_identifier(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'ft_f3_m_reference_data_identifier',
      testname: 'FAIR Test - F3 - Metadata - uses common formats to reference data identifier(s)',
      description: 'This test evaluates whether the metadata record explicitly includes the identifier of the research object(s) it describes. The discovery of a research object should be possible from its metadata. For this to happen, the metadata must explicitly contain the identifier for the digital resource it describes, and this should be present in the form of a qualified reference. This test evaluates whether the identifier provided as input resolves to metadata that contains a research object identifier. Further, that research object identifier must be distinguished from the numerous other fields and values that will be present in the metadata. If the record contains at least one identifier it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'F3', 'reference identifier'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/10.25504/FAIRsharing.0a2061',
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
      distribution = find_schema_object_values(record, 'distribution')
      if distribution.empty?
        response.score = 'fail'
        response.comments << 'This record does not use common formats to reference data identifier(s).'
      else
        distribution[0].each do |dist|
          next unless dist.is_a?(Hash) && dist.include?('@id')

          find_all_schema_object_key_value(record, '@id', dist['@id']).each do |c|
            if c.is_a?(Hash) && c.include?('http://schema.org/identifier') && !c['http://schema.org/identifier'].empty?
              pass = true
              break
            end
          end
          break if pass
        end
      end
      if pass
        response.score = 'pass'
        response.comments << 'This record uses common formats to reference data identifier(s).'
      else
        response.score = 'fail'
        response.comments << 'This record does not use common formats to reference data identifier(s).'
      end
    end

    response.createEvaluationResponse

  end
end
