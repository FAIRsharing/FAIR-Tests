
module FtR12MFsRecordContact
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_2_m_fs_record_contact(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_2_M_FS_RecordContact.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - Database supports contact information for records',
      description: 'This test evaluates whether the database supports contact information for records. In FAIRsharing, this corresponds to a value of yes for the Data Contact Information field within the Additional Information section. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.2', 'FAIRsharing', 'record contact'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8838',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_fs_record_contact',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_fs_record_contact/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if record['registry'] == 'Database'
        if !record['metadata']['data_contact_information'].nil? && record['metadata']['data_contact_information'] == 'yes'
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database supports contact information for records.'
        else
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not support contact information for records.'
        end
      else
        response.comments << 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'A matching record was not found in FAIRsharing.'
    end

    response.createEvaluationResponse
  end
end
