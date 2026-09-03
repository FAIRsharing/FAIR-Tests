# frozen_string_literal: true

# Implements the R1.2 original-source provenance test.
module FtR12MOriginalSource
  require_relative '../fair_test_utils'
  include FairTestUtils

  ORIGINAL_SOURCE_NAME = 'ORA Deposit'
  ORIGINAL_SOURCE_RELATION_TYPE = 'IsVersionOf'
  TEST_DESCRIPTION = 'This test checks for at least one qualified reference to the original source content. ' \
                     'Where applicable, metadata may describe the original source of the record (e.g., OpenAlex ' \
                     'ingestion, direct deposit, or other methodologies). A qualified reference here is a metadata ' \
                     'field for the original source of the object. Expected input is an identifier such as a DOI or ' \
                     'URL.'
  TEST_META = {
    testid: 'FT_R1_2_M_OriginalSource.ttl',
    testname: 'FAIR Test - R1.2 - Metadata - Original Source',
    description: TEST_DESCRIPTION,
    keywords: ['ARK', 'FAIR', 'R1.2', 'original source'],
    creator: 'https://orcid.org/0000-0002-6468-9260',
    indicators: [],
    metric: 'https://fairsharing.org/7991', # principle: https://fairsharing.org/6313
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
    #   "@type": "Dataset",
    #   "name": "ORA Deposit",
    #   "url": "https://deposit.ora.ox.ac.uk/"
    # }
    # A pass would have isBasedOn['name'] == "ORA Deposit"
    # If it's come from Datacite then this will presumably be the data structure to look for:
    # relatedIdentifiers =>
    # [{"relationType" => "IsVersionOf", "relatedIdentifier" => "10.5287/ora-6raddkrg9",
    #   "relatedIdentifierType" => "DOI"}]
    # So, any relatedIdentifiers with relationType 'isVersionOf' and a valid identifier would pass.

    evaluate_original_source(response, record, doi_record)
    response.createEvaluationResponse
  end

  private

  def original_source_identifier?(related_identifier)
    return false unless related_identifier.is_a?(Hash)
    return false unless original_source_relation?(related_identifier)

    identifiers = schema_object_values(related_identifier, 'relatedIdentifier')
    identifier_types = schema_object_values(related_identifier, 'relatedIdentifierType')
    identifier_types.product(identifiers).any? { |type, identifier| valid_related_identifier?(type, identifier) }
  end

  def original_source_relation?(related_identifier)
    schema_object_values(related_identifier, 'relationType').any? do |relation_type|
      relation_type.to_s.casecmp?(ORIGINAL_SOURCE_RELATION_TYPE)
    end
  end

  def valid_related_identifier?(identifier_type, identifier)
    case identifier_type.to_s.upcase
    when 'DOI' then is_doi?(identifier.to_s.strip)
    when 'URL' then valid_url?(identifier)
    else contains_meaningful_value?(identifier)
    end
  end

  def evaluate_original_source(response, record, doi_record)
    if record.nil? || record.empty?
      response.score = 'indeterminate'
      response.comments << 'No record matching the provided identifier was found.'
      return
    end

    pass = doi_record ? datacite_original_source?(record) : jsonld_original_source?(record)
    response.score = pass ? 'pass' : 'fail'
    qualifier = pass ? 'contains' : 'does not contain'
    response.comments << "This record #{qualifier} a qualified reference to its original source."
  end

  def datacite_original_source?(record)
    find_schema_object_values(record, 'relatedIdentifiers').any? do |identifier|
      original_source_identifier?(identifier)
    end
  end

  def jsonld_original_source?(record)
    find_schema_object_values(record, 'isBasedOn').any? do |source|
      source.is_a?(Hash) && schema_object_values(source, 'name').any? do |name|
        name.to_s.strip == ORIGINAL_SOURCE_NAME
      end
    end
  end
end
