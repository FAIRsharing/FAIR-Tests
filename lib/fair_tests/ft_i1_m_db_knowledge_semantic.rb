module FtI1MDbKnowledgeSemantic
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i1_m_db_knowledge_semantic(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    data_test = {
      test_title_short: 'FAIR Test - I1 – Metadata - Database-level knowledge representation languages (semantic)',
      test_title: 'Output from running test: FAIR Test - I1 - Metadata - Database-level knowledge representation languages (semantic)',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FT_I1_M_DbKnowledgeSemantic.ttl',
      description: 'This test checks that the database uses semantic knowledge representation languages.',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_i1_m_db_knowledge_semantic/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_i1_m_db_knowledge_semantic',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)
    if record
      if record['registry'] == 'Database'
        if record['format'] == 'semantic'
          response[:value] = 'pass'
          response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database uses semantic database-level knowledge representation languages.'
        else
          response[:value] = 'fail'
          response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database does not use semantic database-level knowledge representation languages.'
        end
      else
        response[:value] = 'fail'
        response[:description] = 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response[:value] = 'indeterminate'
      response[:description] = 'A matching record was not found in FAIRsharing.'
    end
    response[:log] = response[:description]
    response
  end
end