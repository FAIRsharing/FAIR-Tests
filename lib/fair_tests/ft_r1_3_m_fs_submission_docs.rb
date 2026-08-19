
module FtR13MFsSubmissionDocs
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_3_m_fs_submission_docs(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_3_M_FS_SubmissionDocs.ttl',
      testname: 'FAIR Test - R1.3 - Metadata - Resource documents user-facing data submission',
      description: 'This test evaluates whether the database, standard or policy resource documents user-facing submission processes. In FAIRsharing, this corresponds to documentation associated with at least one Data Process whose access method is User Interface and whose process type includes Write or Read/Write. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.3', 'FAIRsharing', 'documents user-facing submission processes'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8849/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_fs_submission_docs',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_fs_submission_docs/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if %w[Database Policy Standard].include? record['registry']
        pass = false
        unless record['metadata']['data_processes_and_conditions'].nil? || record['metadata']['data_processes_and_conditions'].empty?
          record['metadata']['data_processes_and_conditions'].each do |proc|
            next unless proc['type'].downcase.include?('write') &&
               proc['access_method'] == 'User interface'  &&
               proc.include?('documentation_url') && proc['documentation_url'].strip != ''

            pass = true
            response.score = 'pass'
            response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource documents user-facing data submission.'
            break
          end
        end
        unless pass
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not document user-facing data submission.'
        end
      else
        response.comments << 'The record exists in FAIRsharing but it is not a database, standard or policy.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'A matching record was not found in FAIRsharing.'
    end

    response.createEvaluationResponse
  end
end
