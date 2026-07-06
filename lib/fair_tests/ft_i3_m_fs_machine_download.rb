
module FtI3MFsMachineDownload
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_i3_m_fs_machine_download(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_I3_M_FS_MachineDownload.ttl',
      testname: 'FAIR Test - I3 - allows content download by machines',
      description: 'This test uses the structured metadata provided by FAIRsharing records to determine whether the resource under evaluation allows content to be downloaded through computational interfaces. Machine-mediated download mechanisms are important FAIR-enabling characteristics because they support the automated exchange of information between resources and external systems. This test assesses whether the FAIRsharing record contains at least one Data Process whose label contains "Download" or "Export", whose type is Read or Read/Write, and whose access method is not User Interface. The test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'I3', 'FAIRsharing', 'machine content download'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8413/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i3_m_fs_machine_download',
      endpoint_description: 'https://fair-tests.fairsharing.org/ft_i3_m_fs_machine_download/api',
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
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not allow content download by machines.'
        else
          response.score = 'fail'
          pass = false
          record['metadata']['data_processes_and_conditions'].each do |proc|
            if proc['type'].downcase.include?('read') &&
              proc['access_method'] != 'User interface'  &&
              (proc['name'].downcase.include?('download') || proc['name'].downcase.include?('export')) && !pass
              pass = true
              response.score = 'pass'
              response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database allows content download by machines.'
            end
          end
          unless pass
            response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not allow content download by machines.'
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
