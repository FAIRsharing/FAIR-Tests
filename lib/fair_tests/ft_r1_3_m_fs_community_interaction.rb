
module FtR13MFsCommunityInteraction
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_3_m_fs_community_interaction(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_3_M_FS_CommunityInteraction.ttl',
      testname: 'FAIR Test - R1.3 - Metadata - Resource supports community interaction',
      description: 'This test evaluates whether the database, standard or policy supports community interaction. In FAIRsharing, this corresponds to at least one Support Link relevant to community discussion channels, specifically forums, Facebook, or Twitter/X. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.3', 'FAIRsharing', 'community interaction'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8862',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_fs_community_interaction',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_fs_community_interaction/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if %w[Database Policy Standard].include? record['registry']
        pass = false
        unless record['metadata']['support_links'].nil? || record['metadata']['support_links'].empty?
          record['metadata']['support_links'].each do |sup|
            next unless %w[Forum Facebook Twitter].include?(sup['type'])

            pass = true
            response.score = 'pass'
            response.comments << 'Using FAIRsharing metadata for the database under evaluation, the resource supports community interaction.'
            break
          end
        end
        unless pass
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not support community interaction.'
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
