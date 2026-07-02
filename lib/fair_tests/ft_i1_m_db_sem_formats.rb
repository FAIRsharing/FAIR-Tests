module FtI1MDbSemFormats
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i1_m_db_sem_formats(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end


    meta = {
      testid: 'FT_I1_M_DbSemFormats.ttl',
      testname: 'FAIR Test - I1 - Metadata - Adopts Semantic Knowledge Representation Languages',
      description: "FAIR Test - I1 - Metadata - Adopts Semantic Knowledge Representation Languages evaluates whether the FAIRsharing record is linked to at least one model/format record classified as a semantic knowledge representation language. This test uses the relationships provided within FAIRsharing records to determine whether the resource adopts formats that provide structured semantic representations of information as defined by FAIRsharing. Specifically, to discover a database's relationship to a Semantic model/format, traverse the hierarchy of each model/format directly linked to the database record to identify the underlying generic format: JSON-LD, RDF, RDF/XML, TriG, N-Quads, RDFa, OWL, OBO, TTL, N-triples. To pass, a relationship with one of the previous model/format should exist, else the test will fail.",
      keywords: ['FAIR', 'I1', 'Semantic knowledge representation languages'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8402/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i1_m_db_sem_formats',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_i1_m_db_sem_formats/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record
      if record['registry'] == 'Database'
        if record['format'].include?('semantic')
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database adopts semantic database-level knowledge representation languages.'
        else
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not adopt semantic database-level knowledge representation languages.'
        end
      else
        response.score = 'fail'
        response.comments << 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'A matching record was not found in FAIRsharing.'
    end

    response.createEvaluationResponse

  end



end
