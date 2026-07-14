# frozen_string_literal: true

module FtA1MFsDocumentsCompAccess
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_a1_m_fs_documents_comp_access(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'FT_A1_M_FS_documentsCompAccess.ttl',
      testname: 'FAIR Test - A1 - Metadata - documents computational access',
      description: 'This test assesses whether the FAIRsharing record contains at least one Data Process that uses an access method other than User Interface, whose process type includes Read or Read/Write, and which includes a documentation_url that is a valid HTTP(S) URL. Tests implementing this metric should expect as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['ARK', 'FAIR', 'A1', 'FAIRsharing', 'computational access', 'documentation'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8380',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_a1_m_fs_documents_comp_access',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_a1_m_fs_documents_comp_access/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta
    )

    if record && !record.empty?
      if record['metadata']['data_processes_and_conditions'].nil? ||
         record['metadata']['data_processes_and_conditions'].empty?
        response.score = 'fail'
        response.comments << 'No data processes found.'
      else
        pass = false
        record['metadata']['data_processes_and_conditions'].each do |proc|
          if proc['type'].downcase.include?('read') &&
             proc['access_method'] != 'User interface' &&
             valid_url?(proc['documentation_url'])
            pass = true
            response.score = 'pass'
            response.comments << 'A non-user-interface process with read or read/write access and documentation was found.'
          end
        end
        unless pass
          response.score = 'fail'
          response.comments << 'No non-user-interface process with read or read/write access and valid documentation was found'
        end
      end
    else
      response.score = 'fail'
      response.comments << 'No valid FAIRsharing record was found.'
    end

    response.createEvaluationResponse
  end

end
