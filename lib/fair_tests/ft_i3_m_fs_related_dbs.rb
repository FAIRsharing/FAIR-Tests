module FtI3MFsRelatedDbs
  require_relative '../fair_test_utils'
  include FairTestUtils


  def ft_i3_m_fs_related_dbs(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_I3_M_FS_relatedDBs.ttl',
      testname: 'FAIR Test - I3 - Metadata - I3 - references related databases',
      description: 'This test assesses whether the FAIRsharing database record contains at least one shares_data_with or related_to relationship linking it to another FAIRsharing database record. Tests implementing this metric should expect as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation. To pass, a relationship with shares_data_with or related_to label with other database should exist, else the test will fail. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'I3', 'FAIRsharing', 'references related databases'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8408/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i3_m_fs_related_dbs',
      endpoint_description: 'https://fair-tests.fairsharing.org/ft_i3_m_fs_related_dbs/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if record['registry'] == 'Database'
        databases_related = record['recordAssociations'].collect do |r|
          if %w[shares_data_with related_to].include?(r['recordAssocLabel']) && r['linkedRecord']['registry'] == 'Database'
            r
          end
        end.compact
        if databases_related.empty?
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not explicitly reference other databases.'
        else
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database explicitly references other databases.'
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
