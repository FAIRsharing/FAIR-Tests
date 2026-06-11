module FtF1MMetadataIdResolvable
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f1_m_metadata_id_resolvable(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'FT_F1_M_MetadataIdResolvable.ttl',
      testname: 'FAIR Test – F1 – Metadata - Metadata contains identifier that is guaranteed resolvable',
      description: "This metric evaluates whether the metadata retrieved from the provided URI contains an identifier that satisfies the FAIRsharing definition of guaranteed resolvability, as aligned with the EOSC PID Policy. Note that it assesses the metadata retrieved from the URI rather than the URI itself. During assessment, the provided URI is resolved in accordance with FAIRsharing’s identifier resolution best practices. If the record contains DOI or ARK identifiers it will pass. If any identifier URLs can be determined as resolvable via FAIRsharing data the test will also pass. Otherwise, it will fail.",
      keywords: ['FAIR', 'F1', 'RID', 'resolvable identifiers'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8203',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/'
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
        response.comments << 'This record does not contain any resolvable identifiers.'
      else
        identifiers.each do |identifier|
          property_ids = schema_object_values(identifier, 'propertyID')
          urls = schema_object_values(identifier, 'url')

          # A DOI will pass, but if it's not marked as such then it needs to be sent to FAIRsharing
          # to test for matches to an appropriate identifier.
          if (property_ids & %w[DOI ARK]).any?
            pass = true
            break
          elsif !urls.empty?
            # Send the URL to FAIRsharing.
            urls.each do |identifier_url|
              records = find_by_regex(identifier_url)['records'] || []
              records.each do |r|
                next unless r.dig('metadata', 'resolvable') && !pass

                pass = true
                break
              end
              break if pass
            end
          end
        end

        if pass
          response.score = 'pass'
          response.comments << 'This record contains a resolvable identifier.'
        else
          response.score = 'fail'
          response.comments << 'This record does not contain any resolvable identifiers.'
        end
      end
    end

    response.createEvaluationResponse

  end
end
