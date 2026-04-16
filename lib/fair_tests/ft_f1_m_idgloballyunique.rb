module FtF1MIdgloballyunique
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f1_m_idgloballyunique(url_record)
    records = find_by_regex(url_record)['records']

    data_test = {
      test_title_short: 'FT_F1_M_IdGloballyUnique',
      test_title: 'FAIR Test - F1 - Metadata - evaluate identifier global uniqueness',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F1_M_IdGloballyUnique.ttl',
      description: "F1 requires that metadata be assigned a globally unique, persistent and resolvable identifier. This test is particularly concerned with the globally uniqueness aspect of GUPRIs; global uniqueness is required to prevent identifier collision across institutions, systems and domains. Otherwise, an identifier shared by multiple resources will confound efforts to describe that resource, or to use the identifier to retrieve it. In this test, the definition of global uniqueness follows the FAIRsharing guidance on Globally Unique, Persistent and Resolvable Identifier (GUPRI) schemas. The identifier being evaluated is checked for a match (using regular expressions) to an existing id schema within FAIRsharing. Pass: There is an id_schema record matching the regular expression that has the globally unique field set to 'true'. Indeterminate: No matching records were found in FAIRsharing. Fail: No indication of this resource having a globally unique identifier was found.",      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f1_m_idgloballyunique/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_f1_m_idgloballyunique',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)

    # Regex match found.
    if records.length.positive?
      pass = false

      records.each do |r|
        next unless r['metadata']['globally_unique'] && !pass

        pass = true
      end

      if pass
        response[:value] = 'pass'
        response[:description] = 'Using FAIRsharing metadata for the record under evaluation, this record has a globally unique identifier.'
      else
        response[:value] = 'fail'
        response[:description] = 'No indication of this resource having a globally unique identifier was found.'
      end
    else
      response[:value] = 'indeterminate'
      response[:description] = 'No FAIRsharing identifier schema record found that matches the provided identifier.'
    end

    response[:log] = response[:description]
    response
  end

end
