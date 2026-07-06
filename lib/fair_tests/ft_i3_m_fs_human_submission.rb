
module FtI3MFsHumanSubmission
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_i3_m_fs_human_submission(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_I3_M_FS_HumanSubmission.ttl',
      testname: 'FAIR Test - I3 - allows content submission by humans',
      description: 'This test uses the structured metadata provided by FAIRsharing database records to determine whether users can submit content through human-accessible interfaces. Human-mediated content submission is an important FAIR-enabling characteristic because it supports the exchange of information between users and databases. This test assesses whether the FAIRsharing database record contains at least one Data Process with a type of Write or Read/Write that uses a User Interface access method. This testd expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'I3', 'FAIRsharing', 'human content submission'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8410/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i3_m_fs_human_submission',
      endpoint_description: 'https://fair-tests.fairsharing.org/ft_i3_m_fs_human_submission/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if record['registry'] == 'Database'
        if record['metadata']['data_processes_and_conditions'].nil? ||
          record['metadata']['data_processes_and_conditions'].empty?
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not allow content submission by humans.'
        else
          response.score = 'fail'
          pass = false
          record['metadata']['data_processes_and_conditions'].each do |proc|
            if proc['type'].downcase.include?('write') &&
              proc['access_method'] == 'User interface' && !pass
              pass = true
              response.score = 'pass'
              response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database allows content submission by humans.'
            end
          end
          unless pass
            response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not allow content submission by humans.'
          end
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
