module FtA2MFsDbpreservation
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_a2_m_fs_dbpreservation(url_record)
    # This test expects a URL to be sent, and so if the url_record field is passed directly to get_fairsharing_record
    # it should be evaluated as a URL and passed to FairsharingRecord.find_by_identifier.
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'FM_A2_M_FS_dbPreservation.ttl',
      testname: 'FAIR Test - A2 - database declares preservation policy',
      description: 'This test uses the structured metadata provided by FAIRsharing database records to determine whether the database provides information describing its commitments to preservation. Preservation information is an important FAIR-enabling characteristic for understanding how a database intends to preserve its records over time. This supports FAIR Principle A2 by making preservation commitments discoverable through FAIRsharing. The presence of a Preservation Policy URL does not imply that the underlying policy is adequate, implemented, or effective; it only demonstrates that preservation information has been provided. This metric assesses whether the FAIRsharing database record contains a non-empty Preservation Policy URL. This test should expect as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation. The evaluation retrieves the FAIRsharing record for the database and checks for the presence of a value in the “Data Preservation Policy” field, as defined in the FAIRsharing database conditions documentation. The presence of a declared preservation policy in the FAIRsharing record is interpreted as evidence that the database has articulated commitments to long-term metadata availability. If a preservation policy is listed in the FAIRsharing record, the resource passes this metric; if not, it fails.',
      keywords: ['FAIR', 'A2', 'preservation policy'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8383',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_a2_m_fs_dbpreservation',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_a2_m_fs_dbpreservation/api',
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
