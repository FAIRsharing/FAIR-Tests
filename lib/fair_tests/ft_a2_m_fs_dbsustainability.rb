module FtA2MFsDbsustainability
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_a2_m_fs_dbsustainability(url_record)
    # This test expects a URL to be sent, and so if the url_record field is passed directly to get_fairsharing_record
    # it should be evaluated as a URL and passed to FairsharingRecord.find_by_identifier.
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'FT_A2_M_FS_dbSustainability.ttl',
      testname: 'FAIR Test - A2 - database declares sustainability plan',
      description: 'This test assesses whether the FAIRsharing database record contains a non-empty Resource Sustainability URL. This test uses the structured metadata provided by FAIRsharing database records to determine whether the database provides information describing its long-term sustainability. Sustainability information is an important FAIR-enabling characteristic because users, funders, database managers, and assessment services need to understand how a database plans to remain available over time. This supports FAIR Principle A2 by making sustainability commitments discoverable through FAIRsharing. The presence of a Resource Sustainability URL does not imply that the underlying sustainability information is adequate, implemented, or effective; it only demonstrates that sustainability information has been provided. This test should expect as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'A2', 'sustainability plan'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8387',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_a2_m_fs_dbsustainability',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_a2_m_fs_dbsustainability/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    # Perform the test
    if record && !record.empty?
      if record['registry'] == 'Database'
        if record['metadata'].include?('resource_sustainability') && record['metadata']['resource_sustainability'].include?('url') && !record['metadata']['resource_sustainability']['url'].strip.empty?
          response.score = 'pass'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database declares a sustainability plan."
        else
          response.score = 'fail'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database does not declare a sustainability plan."
        end
      else
        response.score = 'fail'
        response.comments << "The record exists in FAIRsharing (https://fairsharing.org/#{record['id']}) but it is not a database."
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record was found matching the provided identifier.'
    end

    response.createEvaluationResponse
  end
end
