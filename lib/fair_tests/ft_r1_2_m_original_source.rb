# frozen_string_literal: true

# Implements the R1.2 original-source provenance test.
module FtR12MOriginalSource
  require_relative '../fair_test_utils'
  include FairTestUtils

  TEST_DESCRIPTION = 'This test checks for at least one qualified reference to the original source content. ' \
                     'Where applicable, metadata may describe the original source of the record (e.g., OpenAlex ' \
                     'ingestion, direct deposit, or other methodologies). A qualified reference here is a metadata ' \
                     'field for the original source of the object. Expected input is an identifier such as a DOI or ' \
                     'URL.'
  TEST_META = {
    testid: 'FT_R1_2_M_OriginalSource.ttl',
    testname: 'FAIR Test - R1.2 - Metadata - Original Source',
    description: TEST_DESCRIPTION,
    keywords: ['FAIR', 'R1.2', 'original source'],
    creator: 'https://orcid.org/0000-0002-6468-9260',
    indicators: [],
    metric: 'https://doi.org/10.25504/FAIRsharing.4264f7', # principle: https://fairsharing.org/6313
    license: 'https://creativecommons.org/licenses/by/4.0/',
    testversion: '1.0.0',
    protocol: 'https',
    host: 'ostrails.github.io',
    basePath: '/assessment-component-metadata-records/test/',
    endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_original_source',
    endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_original_source/api'
  }.freeze

  def ft_r1_2_m_original_source(url_record)
    doi_record = is_doi?(url_record)
    record = doi_record ? request_datacite(url_record) : request_jsonld(url_record)

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: TEST_META
    )

    # If the record comes from ORA, it will have this structure:
    # "isBasedOn": {
    #   "@type": "WebSite",
    #   "name": "ORA Deposit",
    #   "url": "https://deposit.ora.ox.ac.uk/"
    # }
    # The important part is isBasedOn -> @type "WebSite"; other values are not relevant.
    # If it's come from Datacite then this will presumably be the data structure to look for:
    # relatedIdentifiers =>
    # [{"relationType" => "IsVersionOf", "relatedIdentifier" => "10.5287/ora-6raddkrg9",
    #   "relatedIdentifierType" => "DOI"}]
    # So, any relatedIdentifiers with relationType 'isVersionOf' and a valid identifier would pass.

    if record && !record.empty?
      pass = false
      values_to_search = [record]

      until values_to_search.empty? || pass
        value = values_to_search.pop

        case value
        when Hash
          value.each do |key, child|
            property_name = key.to_s.split(/[\/#:]/).last

            if doi_record && property_name.casecmp?('relatedIdentifiers')
              related_identifiers = child.is_a?(Array) ? child : [child]
              related_identifiers.each do |related_identifier|
                next unless related_identifier.is_a?(Hash)
                next unless related_identifier['relationType'].to_s.casecmp?('IsVersionOf')

                identifier = related_identifier['relatedIdentifier'].to_s.strip
                identifier_type = related_identifier['relatedIdentifierType'].to_s.strip
                valid_identifier = case identifier_type.downcase
                                   when 'doi'
                                     is_doi?(identifier)
                                   when 'url'
                                     valid_url?(identifier)
                                   else
                                     !identifier.empty?
                                   end

                if valid_identifier
                  pass = true
                  break
                end
              end
            elsif !doi_record && property_name.casecmp?('isBasedOn')
              sources = child.is_a?(Array) ? child : [child]
              sources.each do |source|
                next unless source.is_a?(Hash)

                source_types = Array(source['@type']).map { |type| type.to_s.split(/[\/#:]/).last }
                if source_types.any? { |type| type.casecmp?('WebSite') }
                  pass = true
                  break
                end
              end
            end

            values_to_search << child unless pass
          end
        when Array
          values_to_search.concat(value)
        end
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains a qualified reference to its original source.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain a qualified reference to its original source.'
      end

    else
      response.score = 'indeterminate'
      response.comments << 'No record matching the provided identifier was found.'
    end

    response.createEvaluationResponse
  end

end
