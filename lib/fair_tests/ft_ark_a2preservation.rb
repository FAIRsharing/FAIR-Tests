module FtArkA2preservation
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_ark_a2preservation(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'ft_ark_a2preservation',
      testname: 'FAIR Test - ARK T-A2 - Database has a preservation policy',
      description: 'This test checks that the database requires the presence of a data preservation policy for the database being evaluated. FM ARK A2-Preservation expects a FAIRsharing URL or DOI as its input and evaluates the database described by the FAIRsharing record.',
      keywords: ['ARK', 'FAIR', 'A2', 'GUPRI', 'preservation policy'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/FAIRsharing.lEZbPK',
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
        if record['metadata'].include?('data_preservation_policy') && record['metadata']['data_preservation_policy'].include?('url') && !record['metadata']['data_preservation_policy']['url'].strip.empty?
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database has a data preservation policy.'
        else
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not have a data preservation policy.'
        end
      else
        response.score = 'fail'
        response.comments << 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record was found matching the provided identifier.'
    end

    response.createEvaluationResponse
  end

end
