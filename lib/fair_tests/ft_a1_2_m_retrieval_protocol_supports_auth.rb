# frozen_string_literal: true

module FtA12MRetrievalProtocolSupportsAuth
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_a1_2_m_retrieval_protocol_supports_auth(url_record)
    # In this case we're looking up the record in FAIRsharing via its homepage.
    record = get_fairsharing_record(url_record)

    meta = {
      testid: 'ft_a1_2_m_retrieval_protocol_supports_auth',
      testname: 'FAIR Test – A1.2 – Metadata - retrieval protocol supports auth',
      description: 'A1.2 requires that the protocol used to retrieve research objects clearly describes any necessary authentication and authorisation procedures. This ensures that access conditions are transparent and that restricted content is accessed in a defined and controlled way. Optionally, if a FAIRsharing record for the hosting database is available, the evaluation first checks the declared data access conditions. If the access condition is “open” then no authentication or authorisation is required for any content within that database, and the evaluation is complete. Otherwise, the test currently fails. https://tests.ostrails.eu/tests/test_FM_A1_2_M_Auth should also be run.',
      keywords: ['FAIR', 'A1.2', 'authentication', 'retrieval protocol'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/7834',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: "fair-tests.fairsharing.org",
      basePath: "test"
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if record['registry'] == 'Database'
        if record['metadata']['data_access_condition'] && record['metadata']['data_access_condition'] == 'open'
          response.score = 'pass'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database has open data access."
        else
          response.score = 'fail'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database does not have open data access."
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
