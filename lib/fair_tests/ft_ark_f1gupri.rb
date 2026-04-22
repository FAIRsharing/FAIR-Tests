module FtArkF1gupri
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_ark_f1gupri(url_record)
    record = obtain_record_from_text(url_record)

    data_test = {
      test_title_short: 'FAIR Test - ARK T-F1 - Globally unique, persistent and resolvable identifiers for database content',
      test_title: 'Output from running test: FAIR Test - ARK T-F1 - Globally unique, persistent and resolvable identifiers for database content (https://tools.ostrails.eu/fdp-index/entry/22e84d01-e3fa-4f31-9648-9f87693a7a92)',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FTARKTF1GUPRI.ttl',
      description: 'This test checks that the database requires the minting of community-relevant, publicly available GUPRIs (Globally unique, persistent and resolvable identifiers) for at least some of the content within the database being evaluated.',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_ark_f1gupri/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_ark_f1gupri',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)
    response[:value] = 'indeterminate'
    response[:description] = 'No record was found matching the provided identifier.'

    if record && !record.empty?
      if record['registry'] == 'Database'
        identified_rel = record['recordAssociations'].collect { |r| r if r['recordAssocLabel'] == 'implements' && r['linkedRecord']['type'] == 'identifier_schema' }.compact
        response[:value] = 'fail'
        response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database does not mint globally unique, persistent and resolvable identifiers.'
        identified_rel.each do |ir|
          next unless ir['linkedRecord']['metadata']['persistent'] && ir['linkedRecord']['metadata']['globally_unique'] && ir['linkedRecord']['metadata']['resolvable']

          response[:value] = 'pass'
          response[:description] = 'Using FAIRsharing metadata for the database under evaluation, the database mints globally unique, persistent and resolvable identifiers.'
          break
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
