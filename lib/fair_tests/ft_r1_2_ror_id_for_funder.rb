module FtR12RorIdForFunder
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_2_ror_id_for_funder(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'ft_r1_2_ror_id_for_funder',
      testname: 'FAIR Test – R1.2 - ROR ID for funder',
      description: 'This test evaluates whether the metadata includes at least one ROR ID for a funder associated with the research object. The assessment checks for structured funding references within both the landing page metadata and the central records held by DOI registration agencies (such as DataCite or Crossref). Specifically, it verifies that fields such as fundingReferences (DataCite) or funder (Crossref) are populated with at least one funder ROR ID. It checks the record’s landing page for embedded or linked structured data that can be successfully parsed against the declared community schema. If the record contains ROR identifiers it will pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.2', 'ror id'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8185',
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
      if identifiers.empty?
        response.score = 'fail'
        response.comments << 'This record does not contain ROR identifiers.'
      else
        identifiers.each do |identifier|
          property_ids = schema_object_values(identifier, 'propertyID')

          if (property_ids & %w[ROR]).any?
            pass = true
            break
          end
        end

        if pass
          response.score = 'pass'
          response.comments << 'This record contains ROR identifiers.'
        else
          response.score = 'fail'
          response.comments << 'This record does not contain ROR identifiers.'
        end
      end
    end

    response.createEvaluationResponse

  end
end