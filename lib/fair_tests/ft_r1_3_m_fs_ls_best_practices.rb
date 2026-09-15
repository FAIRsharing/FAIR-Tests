
module FtR13MFsLsBestPractices
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_3_m_fs_ls_best_practices(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_3_M_FS_LS_BestPractices.ttl',
      testname: 'FAIR Test - R1.3 - Metadata - Resource follows community-relevant best practices (Life Science)',
      description: 'This test evaluates whether the database, standard or policy follows community-relevant best practices for the Life Science community. To satisfy this test, at least one assigned subject must be within the Life Science hierarchy of the FAIRsharing Subject Resource Application Ontology (SRAO), and at least one related reporting guideline (via any relationship other than deprecates) must have a subject that is identical to or a child of at least one assigned subject within the record under evaluation. In FAIRsharing, this corresponds to reporting guideline records related via any non-deprecates relationship and curated using the Life Science subject criteria outlined above. This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.3', 'FAIRsharing', 'community-relevant best practices', 'Life Science'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8858',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_fs_ls_best_practices',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_fs_ls_best_practices/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if %w[Database Policy Standard].include? record['registry']
        pass = false

        if !record['subjects'].nil? && !record['subjects'].empty? && subject_has_ls_ancestor(record['subjects'])
          subject_ids = record['subjects'].collect do |s|
            s['id']
          end.compact.to_a
          if !record['recordAssociations'].nil? && !record['recordAssociations'].empty?
            record['recordAssociations'].each do |r|
              next if r['recordAssocLabel'] == 'deprecates'
              next unless r['linkedRecord']['type'] == 'reporting_guideline'

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
              next unless r['fairsharingRecord']['type'] == 'reporting_guideline'

              record2 = get_fairsharing_record("https://fairsharing.org/#{r['fairsharingRecord']['id'].to_s}")
              next unless record2 && !record2.empty?

              if subject_appears_or_descendent(subject_ids,  record2['subjects'])
                pass = true
                break
              end
            end
          end
          if pass
            response.score = 'pass'
            response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource follows community-relevant best practices (Life Science).'
          else
            response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not follow community-relevant best practices (Life Science).'
          end
        else
          response.comments << 'The record exists in FAIRsharing but it is not a Life Science resource.'
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
