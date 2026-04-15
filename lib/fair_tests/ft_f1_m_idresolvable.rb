module FtF1MIdresolvable
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f1_m_idresolvable(url_record)
    records = find_by_regex(url_record)['records']

    data_test = {
      test_title_short: 'FT_F1_M_Idresolvable',
      test_title: 'FAIR Test – F1 – Metadata - Evaluate identifier resolvability',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F1_M_IdResolvable.ttl',
      description: 'F1 requires that metadata be assigned a globally unique, persistent and resolvable identifier. This metric is particularly concerned with the resolvability aspect of GUPRIs. Resolvability is required so that identifiers are actionable for both humans and machines. In this metric, the definition of resolvability follows the FAIRsharing guidance on Globally Unique, Persistent and Resolvable Identifier (GUPRI) schemas. The identifier being evaluated is checked for a match (using regular expressions) to an existing id schema within FAIRsharing.',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f1_m_idresolvable/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_f1_m_idresolvable',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)

    # Regex match found.
    if records.length.positive?
      pass = false

      records.each do |r|
        next unless r['metadata']['resolvable'] && !pass

        pass = true
      end

      if pass
        response[:value] = 'pass'
        response[:description] = 'Using FAIRsharing metadata for the record under evaluation, this record has a resolvable identifier.'
      else
        response[:value] = 'fail'
        response[:description] = 'No indication of this resource having a resolvable identifier was found.'
      end
    else
      response[:value] = 'indeterminate'
      response[:description] = 'No matching records were found in FAIRsharing.'
    end

    response[:log] = response[:description]
    response
  end

end
