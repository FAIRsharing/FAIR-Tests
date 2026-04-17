module FtA2MDbpersistencepolicy
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_a2_m_dbpersistencepolicy(url_record)
    # This test expects a URL to be sent, and so if the url_record field is passed directly to get_fairsharing_record
    # it should be evaluated as a URL and passed to FairsharingRecord.find_by_identifier.
    record = get_fairsharing_record(url_record)

    data_test = {
      test_title_short: 'FAIR Test - A2 - Metadata - Database persistence policy',
      test_title: 'Output from running test: FAIR Test - A2 - Metadata - Database has a preservation policy (https://fairsharing.org/7835)',
      test_id: 'TBC', # TODO
      description: 'A2 requires that metadata remain accessible even if the digital object is no longer available. The purpose of this principle is to ensure that information about a resource persists over time, independent of the continued availability of the research object itself. As per FAIR Principle F3, when this metadata remains discoverable, even in the absence of the research object, it will also contain an explicit reference to the identifier of the research object. This metric evaluates whether the hosting database or repository declares a formal data preservation policy. The evaluation retrieves the FAIRsharing record for the database and checks for the presence of a value in the “Data Preservation Policy” field, as defined in the FAIRsharing database conditions documentation. The presence of a declared preservation policy in the FAIRsharing record is interpreted as evidence that the database has articulated commitments to long-term metadata availability. If a preservation policy is listed in the FAIRsharing record, the resource passes this metric; if not, it fails. This metric measures database-level persistence policies as persistence information is rarely included in record-level metadata.',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_a2_m_dbpersistencepolicy/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_a2_m_dbpersistencepolicy',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)

    # Perform the test
    if record && !record.empty?
      if record['registry'] == 'Database'
        if record['metadata'].include?('data_preservation_policy') && record['metadata']['data_preservation_policy'].include?('url') && !record['metadata']['data_preservation_policy']['url'].strip.empty?
          response[:value] = 'pass'
          response[:description] = "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database has a data preservation policy."
        else
          response[:value] = 'fail'
          response[:description] = "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database does not have a data preservation policy."
        end
      else
        response[:value] = 'fail'
        response[:description] = "The record exists in FAIRsharing (https://fairsharing.org/#{record['id']}) but it is not a database."
      end
    else
      response[:value] = 'indeterminate'
      response[:description] = 'No record was found matching the provided identifier.'
    end
    response[:log] = response[:description]
    response

  end
end