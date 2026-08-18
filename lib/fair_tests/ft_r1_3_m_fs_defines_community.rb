
module FtR13MFsDefinesCommunity
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_3_m_fs_defines_community(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_3_M_FS_DefinesCommunity.ttl',
      testname: 'FAIR Test - R1.3 - Metadata - Resource defines its community',
      description: 'This test evaluates whether the database, standard or policy resource defines its community through its assigned disciplines and research object types. To satisfy this test, the resource must have at least one assigned subject and at least one assigned research object type from the OSTrails Digital Object Commons, excluding Object type not found. In FAIRsharing, this corresponds to the presence of at least one subject and at least one object type. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.3', 'FAIRsharing', 'community'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8845/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_fs_defines_community',
      endpoint_description: 'https://fair-tests.fairsharing.org/ft_r1_3_m_fs_defines_community/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if %w[Database Policy Standard].include? record['registry']
        pass = false
        unless record['objectTypes'].nil? || record['objectTypes'].empty?
          record['objectTypes'].each do |ot|
            # ObjectType with id 13 has the label "object type not found"
            # Do we need to find the id each time?
            next if ot['id'] == 13

            pass = true
            response.score = 'pass'
            response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource defines its community.'
            break
          end
        end
        unless pass
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not defines its community.'
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
