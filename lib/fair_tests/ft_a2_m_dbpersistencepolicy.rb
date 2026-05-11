module FtA2MDbpersistencepolicy
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_a2_m_dbpersistencepolicy(url_record)
    # This test expects a URL to be sent, and so if the url_record field is passed directly to get_fairsharing_record
    # it should be evaluated as a URL and passed to FairsharingRecord.find_by_identifier.
    record = get_fairsharing_record(url_record)

    meta = {
      testid: 'ft_a2_m_dbpersistencepolicy',
      testname: 'FAIR Test - A2 - Metadata - Database persistence policy',
      description: 'A2 requires that metadata remain accessible even if the digital object is no longer available. The purpose of this principle is to ensure that information about a resource persists over time, independent of the continued availability of the research object itself. As per FAIR Principle F3, when this metadata remains discoverable, even in the absence of the research object, it will also contain an explicit reference to the identifier of the research object. This metric evaluates whether the hosting database or repository declares a formal data preservation policy. The evaluation retrieves the FAIRsharing record for the database and checks for the presence of a value in the “Data Preservation Policy” field, as defined in the FAIRsharing database conditions documentation. The presence of a declared preservation policy in the FAIRsharing record is interpreted as evidence that the database has articulated commitments to long-term metadata availability. If a preservation policy is listed in the FAIRsharing record, the resource passes this metric; if not, it fails. This metric measures database-level persistence policies as persistence information is rarely included in record-level metadata.',
      keywords: ['FAIR', 'A2', 'persistence policy'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/7835',
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

    # Perform the test
    if record && !record.empty?
      if record['registry'] == 'Database'
        if record['metadata'].include?('data_preservation_policy') && record['metadata']['data_preservation_policy'].include?('url') && !record['metadata']['data_preservation_policy']['url'].strip.empty?
          response.score = 'pass'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database has a data preservation policy."
        else
          response.score = 'fail'
          response.comments << "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database does not have a data preservation policy."
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