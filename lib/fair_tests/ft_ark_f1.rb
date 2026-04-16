module FtArkF1
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_ark_f1(url_record)
    record = obtain_record_from_text(url_record)

    data_test = {
      test_title_short: 'FAIR Test - ARK T-F1 - Persistent Identifiers for Database Content',
      test_title: 'Output from running test: FAIR Test - ARK T-F1 - Persistent Identifiers for Database Content (https://tools.ostrails.eu/fdp-index/entry/210ea450-9e80-4559-9e40-a2c8df242728)',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FTARKTF1.ttl',
      description: 'This test checks that the database requires the minting of persistent identifiers for at least some of the content within the database being evaluated.',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_ark_f1/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_ark_f1',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)

    if record && !record.empty?
      if record['registry'] == 'Database'
        identified_rel = record['recordAssociations'].collect { |r| r if r['recordAssocLabel'] == 'implements' && r['linkedRecord']['type'] == 'identifier_schema' }.compact
        response[:value] = 'fail'
        response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database does not mint any persistent identifiers.'
        identified_rel.each do |ir|
          next unless ir['linkedRecord']['metadata']['persistent']

          response[:value] = 'pass'
          response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database mints persistent identifiers.'
          break
        end
      else
        response[:value] = 'fail'
        response[:description] = 'The record exists in FAIRsharing but it is not a database.'
      end
    else

    end
    response[:log] = response[:description]
    response
  end

end
