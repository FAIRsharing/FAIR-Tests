
module FtR12MFsFundingOrganisation
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_2_m_fs_funding_organisation(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_2_M_FS_FundingOrganisation.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - Resource declares funding organisations',
      description: 'This test evaluates whether the database, standard or policy resource declares one or more funding organisations. In FAIRsharing, this corresponds to at least one linked organisation with the Funder role. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.2', 'FAIRsharing', 'funding organisation'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8840',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_fs_funding_organisation',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/funding_organisation/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if %w[Database Policy Standard].include? record['registry']
        pass = false
        unless record['organisationLinks'].nil? || record['organisationLinks'].empty?
          record['organisationLinks'].each do |ol|
            if ol['relation'] == 'funds'
              pass = true
              response.score = 'pass'
              response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource declares funding organisations.'
              break
            end
          end
        end
        unless pass
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not declare funding organisations/'
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
