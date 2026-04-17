module FtArkA2preservation
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_ark_a2preservation(url_record)
    record = obtain_record_from_text(url_record)

    data_test = {
      test_title_short: 'FAIR Test - ARK T-A2 - Database has a preservation policy',
      test_title: 'Output from running test: FAIR Test - ARK T-A2 - Database has a preservation policy (https://tools.ostrails.eu/fdp-index/entry/fde06b8b-77f7-4e5b-8e88-0f8f7c1bf7ab)',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FTARKTA2Preservation.ttl',
      description: 'This test checks that the database requires the presence of a data preservation policy for the database being evaluated. FM ARK A2-Preservation expects a FAIRsharing URL or DOI as its input and evaluates the database described by the FAIRsharing record.',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_ark_a2preservation/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_ark_a2preservation',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)
    response[:value] = 'indeterminate'
    response[:description] = 'No record was found matching the provided identifier.'

    if record && !record.empty?
      if record['registry'] == 'Database'
        if record['metadata'].include?('data_preservation_policy') && record['metadata']['data_preservation_policy'].include?('url') && !record['metadata']['data_preservation_policy']['url'].strip.empty?
          response[:value] = 'pass'
          response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database has a data preservation policy.'
        else
          response[:value] = 'fail'
          response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database does not have a data preservation policy.'
        end
      else
        response[:value] = 'fail'
        response[:description] = 'The record exists in FAIRsharing but it is not a database.'
      end
    end
    response[:log] = response[:description]
    response
  end

end
