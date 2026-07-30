# frozen_string_literal: true
# Run this with:
# ruby ./scripts/ersatz_algorithm.rb
# To run all the tests at:
# https://docs.google.com/spreadsheets/d/1Lbo0KzlN-RPRJ5POqHKh8YE2GXSv0bnaKZzwkaCOP9M/edit?gid=1285434259#gid=1285434259
require 'httparty'
require 'json'
require 'rdf/turtle'

DEFAULT_ORA_IDENTIFIER = 'https://ora.ox.ac.uk/objects/uuid:ad7da8fc-cd8e-4637-8b7c-99498436dbaa'
DCAT_ENDPOINT_URL = RDF::URI('http://www.w3.org/ns/dcat#endpointURL')
TESTS = {
  'F1_Unique':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F1_M_MetadataIdUnique.ttl',
  'F1_Resolve':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F1_M_MetadataIdResolvable.ttl',
  'F1_Persist':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F1_M_MetadataIdPersistent.ttl',
  'F2_PublisherInfo':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F2_M_Discoverypublisher.ttl',
  'F2_Fields':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F2_M_Discoveryfields.ttl',
  'F2_Tags':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F2_M_Discoverytags.ttl',
  'F3_SelfID':	'https://tests.ostrails.eu/tests/test_FM_F3_M_MetaIdent',
  'F3_DataID':	'https://tests.ostrails.eu/tests/test_FM_F3_M_DataIdent',
  'F4_GenericSearch':	'https://tests.ostrails.eu/tests/test_FM_F4_M_MetaIndexed',
  'A1_1_HTTP':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_A1.1_M_HTTPSRetrievalProtocol.ttl',
  'A1_2_FS_Auth':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_A1-2_M_Auth.ttl',
  'A2_Policy':	'https://ostrails.github.io/assessment-component-metadata-records/test/FTA2MDbPersistencepolicy.ttl',
  'I1_DBSem':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_I1_M_DbKnowledgeSemantic.ttl',
  'I3_Related':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_I3_M_ReferenceResearchObjects.ttl',
  'R1_1_DBLic':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_R1_1_M_DatabaseLevelLicenses.ttl',
  'R1_1_DataLic':	'https://tests.ostrails.eu/tests/test_FM_R1_1_M_StdLic',
  'R1_2_ORCID':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_R1_2_M_CreatorORCID.ttl',
  'R1_2_Fund':	'https://tests.ostrails.eu/community-tests/community_funding_information_registered',
  'R1_2_FundROR':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_R1_2_M_FundROR.ttl',
  'R1_2_Affil':	'https://tests.ostrails.eu/community-tests/community_metadata_includes_author_affiliation',
  'R1_2_Pubs':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_R1_2_M_LinkedPublications.ttl',
  'R1_3_ISO639':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_R1.3_M_UsesISO639.ttl',
  'R1_3_GenFormat':	'https://ostrails.github.io/assessment-component-metadata-records/test/FT_R1_3_M_UseStuctGenericFormat.ttl',
}
HEADERS = {
  'Accept' => 'application/ld+json',
  'Content-Type' => 'application/ld+json'
}

def extract_endpoint_url(url)
  response = HTTParty.get(url, headers: { 'Accept' => 'text/turtle' })
  raise "Could not retrieve #{url}: HTTP #{response.code}" unless response.success?

  statement = RDF::Turtle::Reader.new(response.body, base_uri: url).find do |triple|
    triple.predicate == DCAT_ENDPOINT_URL
  end

  statement&.object&.to_s
end

def parse_result(response_body)
  nodes = [JSON.parse(response_body)]

  until nodes.empty?
    node = nodes.shift

    if node.is_a?(Hash)
      value = node['prov:value']
      return value['@value'] if value.is_a?(Hash) && value.key?('@value')

      nodes.concat(node.values)
    elsif node.is_a?(Array)
      nodes.concat(node)
    end
  end

  nil
end

TESTS.each_pair do |key, value|
  endpoint = extract_endpoint_url(value)
  response = HTTParty.post(endpoint,
                           body: { resource_identifier: DEFAULT_ORA_IDENTIFIER }.to_json,
                           headers: HEADERS
                          )

  result = parse_result(response.body)
  puts "#{key}:\t#{result}"
end
