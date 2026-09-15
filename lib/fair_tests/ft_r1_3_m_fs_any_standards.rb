
module FtR13MFsAnyStandards
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_3_m_fs_any_standards(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_3_M_FS_AnyStandards.ttl',
      testname: 'FAIR Test - R1.3 - Metadata - Resource adopts one or more community or general standards',
      description: 'This test evaluates whether the database, standard or policy adopts one or more community or general standards. In FAIRsharing, this corresponds to the presence of at least one related terminology artefact, model/format or reporting guideline record via any non-deprecates relationship. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.3', 'FAIRsharing', 'standards'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8859',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_fs_any_standards',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_fs_any_standards/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if %w[Database Policy Standard].include? record['registry']
        stardards_related = []
        unless record['recordAssociations'].nil? || record['recordAssociations'].empty?
          stardards_related = record['recordAssociations'].collect do |r|
            if r['recordAssocLabel'] != 'deprecates' && %w[terminology_artefact model_and_format reporting_guideline].include?(r['linkedRecord']['type'])
              r
            end
          end.compact
        end
        if stardards_related.empty? && !record['reverseRecordAssociations'].nil? && !record['reverseRecordAssociations'].empty?
          stardards_related = record['reverseRecordAssociations'].collect do |r|
            if r['recordAssocLabel'] != 'deprecates' && %w[terminology_artefact model_and_format reporting_guideline].include?(r['fairsharingRecord']['type'])
              r
            end
          end.compact
        end
        if stardards_related.empty?
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not adopt one or more community or general standards.'
        else
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource adopts one or more community or general standards.'
        end
      else
        response.score = 'fail'
        response.comments << 'The record exists in FAIRsharing but it is not a database, standard or policy.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'A matching record was not found in FAIRsharing.'
    end

    response.createEvaluationResponse
  end
end
