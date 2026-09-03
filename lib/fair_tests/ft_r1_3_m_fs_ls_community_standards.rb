
module FtR13MFsLsCommunityStandards
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_3_m_fs_ls_community_standards(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_3_M_FS_LS_CommunityStandards.ttl',
      testname: 'FAIR Test - R1.3 - Metadata - Resource adopts community-relevant terminologies or models/formats (Life Science)',
      description: 'This test whether the database, standard or policy adopts community-relevant terminologies or models/formats for the Life Science community. To satisfy this test, at least one assigned subject must be within the Life Science hierarchy of the FAIRsharing Subject Resource Application Ontology (SRAO), and at least one related terminology and/or model/format must have a subject that is identical to or a child of at least one assigned subject within the resource record. In FAIRsharing, this corresponds to terminology artefacts and/or model/format records related via any non-deprecates relationship and curated using the Life Science subject criteria outlined above. Expected input is the DOI or URL of the registry (e.g. FAIRsharing) record under evaluation. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.3', 'FAIRsharing', 'community standards', 'Life Science'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.356855',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_fs_ls_community_standards',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_fs_ls_community_standards/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?


      if %w[Database Policy Standard].include? record['registry']
        pass = false

        if !record['subjects'].nil? && !record['subjects'].empty? && subject_has_ls_ancestor(record['subjects'])
          subject_ids = record['subjects'].collect do |s|
            s['id']
          end.compact.to_a
          if !record['recordAssociations'].nil? && !record['recordAssociations'].empty?
            record['recordAssociations'].each do |r|
              next if r['recordAssocLabel'] == 'deprecates'
              next unless %w[terminology_artefact model_and_format].include?(r['linkedRecord']['type'])

              record2 = get_fairsharing_record("https://fairsharing.org/#{r['linkedRecord']['id'].to_s}")
              next unless record2 && !record2.empty?

              if subject_appears_or_descendent(subject_ids,  record2['subjects'])
                pass = true
                break
              end
            end
          end
          if !pass && !record['reverseRecordAssociations'].nil? && !record['reverseRecordAssociations'].empty?
            record['reverseRecordAssociations'].each do |r|
              next if r['recordAssocLabel'] == 'deprecates'
              next unless %w[terminology_artefact model_and_format].include?(r['fairsharingRecord']['type'])

              record2 = get_fairsharing_record("https://fairsharing.org/#{r['fairsharingRecord']['id'].to_s}")
              next unless record2 && !record2.empty?

              if subject_appears_or_descendent(subject_ids,  record2['subjects'])
                pass = true
                break
              end
            end

          end
        end
        if pass
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource adopts community-relevant terminologies or models/formats (Life Science).'
        else
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not adopt community-relevant terminologies or models/formats (Life Science).'
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
