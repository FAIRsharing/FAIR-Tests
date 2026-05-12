module FtI1MDbKnowledgeSemantic
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i1_m_db_knowledge_semantic(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'ft_i1_m_db_knowledge_semantic',
      testname: 'FAIR Test - I1 – Metadata - Database-level knowledge representation languages (semantic)',
      description: "This test checks that the database uses semantic knowledge representation languages.",
      keywords: ['FAIR', 'I1', 'semantic'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.9114a7',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: "fair-tests.fairsharing.org",
      basePath: "test"
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record
      if record['registry'] == 'Database'
        if record['format'] == 'semantic'
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database uses semantic database-level knowledge representation languages.'
        else
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not use semantic database-level knowledge representation languages.'
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