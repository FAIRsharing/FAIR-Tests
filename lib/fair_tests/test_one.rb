module TestOne

  require_relative '../fair_test_utils'
  include FairTestUtils

  def test_one(identifier=nil)

    return {} unless identifier

    response = post_to_test(identifier)

    test_data = {
      test_title_short: 'FAIR Test - ARK T-F1 - Persistent Identifiers for Database Content',
      test_title: 'Output from running test: FAIR Test - ARK T-F1 - Persistent Identifiers for Database Content (https://tools.ostrails.eu/fdp
-index/entry/210ea450-9e80-4559-9e40-a2c8df242728)',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FTARKTF1.ttl',
      description: 'This test checks that the database requires the minting of persistent identifiers for at least some of the content within
the database being evaluated.',
      endpointDescription: 'https://api.fairsharing.org/test_descriptions/ft_ark_f1/api',
      endpointURL: 'https://api.fairsharing.org/fair_tests/ft_ark_f1',
      url_record: response['response']['document']['abstract']
    }

    fair_test_response_basics(test_data)
  end

end
