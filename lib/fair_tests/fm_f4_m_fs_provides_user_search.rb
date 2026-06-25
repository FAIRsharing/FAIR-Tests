# frozen_string_literal: true

module FmF4MFsProvidesUserSearch
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def fm_f4_m_fs_provides_user_search(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'FM_F4_M_FS_providesUserSearch.ttl',
      testname: 'FAIR Test - F4 - provides user search',
      description: 'This test assesses whether the FAIRsharing record contains at least one Data Process that includes a Search or Browse function (as identified by “Search” or “Browse” within the Name field of a Data Process), uses a User Interface access method, and supports Read or Read/Write operations. The test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['ARK', 'FAIR', 'F4', 'FAIRsharing', 'user search'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8376',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/fm_f4_m_fs_provides_user_search',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/fm_f4_m_fs_provides_user_search/api',
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
          if Array(proc['type']).any? { |type| type.to_s.downcase.include?('read') } &&
             proc['access_method'] == 'User interface' &&
             (proc['name'].downcase.include?('search') || proc['name'].downcase.include?('browse')) && !pass
            pass = true
            response.score = 'pass'
            response.comments << 'A search or browse user interface function was found'
          end
        end
        unless pass
          response.score = 'fail'
          response.comments << 'No search or browse user interface function was found'
        end
      end
    else
      response.score = 'fail'
      response.comments << 'No valid FAIRsharing record was found.'
    end

    response.createEvaluationResponse
  end
end
