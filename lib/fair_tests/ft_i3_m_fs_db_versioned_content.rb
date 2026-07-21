
module FtI3MFsDbVersionedContent
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_i3_m_fs_db_versioned_content(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_I3_M_FS_DbVersionedContent.ttl',
      testname: 'FAIR Test - I3 - database supports versioned content',
      description: 'This test uses the structured metadata provided by FAIRsharing database records to determine whether the database supports versioned content. Versioning is an important FAIR-enabling characteristic because it provides explicit relationships between different states of content over time, helping users and systems understand how content changes and evolves.  This test assesses whether the FAIRsharing database record has Data Versioning set to "yes". This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'I3', 'FAIRsharing', 'supports versioned content'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8409/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i3_m_fs_db_versioned_content',
      endpoint_description: 'https://fair-tests.fairsharing.org/ft_i3_m_fs_db_versioned_content/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if record['registry'] == 'Database'
        if record['metadata'].include?('data_versioning') && record['metadata']['data_versioning'] == 'yes'
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database supports versioned content.'
        else
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database doe not support versioned content.'
        end
      else
        response.score = 'fail'
        response.comments << 'The record exists in FAIRsharing but it is not a database.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'A matching record was not found in FAIRsharing.'
    end

    response.createEvaluationResponse
  end
end
