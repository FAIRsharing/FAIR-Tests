module FtF1MIdpersistent
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f1_m_idpersistent(url_record)
    records = find_by_regex(url_record)['records']

    data_test = {
      test_title_short: 'FT_F1_M_IdPersistent',
      test_title: 'FAIR Test – F1 – Metadata - evaluate identifier persistence',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F1_M_IdPersistent.ttl',
      description: "F1 requires that metadata be assigned a globally unique, persistent and resolvable identifier. This test is particularly concerned with the persistence aspect of GUPRIs; persistence is required to guarantee long-term continuity of reference. In this test, the definition of persistence follows the FAIRsharing guidance on Globally Unique, Persistent and Resolvable Identifier (GUPRI) schemas. The identifier being evaluated is checked for a match (using regular expressions) to an existing id schema within FAIRsharing. Pass: There is an id_schema record matching the regular expression that has the persistent field set to 'true'. Indeterminate: No matching records were found in FAIRsharing. Fail: No indication of this resource having a persistent identifier was found.",
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f1_m_idpersistent/api',
      endpointURL: 'https://fair-tests.fairsharing.org/fair_tests/ft_f1_m_idpersistent',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)

    # Regex match found.
    if records.length.positive?
      pass = false

      records.each do |r|
        next unless r['metadata']['persistent'] && !pass

        pass = true
      end

      if pass
        response[:value] = 'pass'
        response[:description] = 'Using FAIRsharing metadata for the record under evaluation, this record has a persistent identifier.'
      else
        response[:value] = 'fail'
        response[:description] = 'No indication of this resource having a persistent identifier was found.'
      end
    else
      response[:value] = 'indeterminate'
      response[:description] = 'No FAIRsharing identifier schema record found that matches the provided identifier.'
    end

    response[:log] = response[:description]
    response
  end

end
