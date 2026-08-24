
module FtR12MFsResourceContact
  require_relative '../fair_test_utils'
  include FairTestUtils



  def ft_r1_2_m_fs_resource_contact(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end



    meta = {
      testid: 'FT_R1_2_M_FS_ResourceContact.ttl',
      testname: 'FAIR Test - R1.2 - Metadata - Resource provides contact information',
      description: 'This test evaluates whether the database, standard or policy resource provides contact information for the resource itself. In FAIRsharing, this corresponds to at least one of: Contact Information and/or Support Links fields (mailing list, support email or contact form only). This test expects as input the FAIRsharing DOI or URL for the FAIRsharing record under evaluation.',
      keywords: ['FAIR', 'R1.2', 'FAIRsharing', 'resource contact'],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8839',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_2_m_fs_resource_contact',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_2_m_fs_resource_contact/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      response.score = 'fail'
      if %w[Database Policy Standard].include? record['registry']
        if !record['metadata']['contacts'].nil? && !record['metadata']['contacts'].empty?
          response.score = 'pass'
        else
          if !record['metadata']['support_links'].nil? && !record['metadata']['support_links'].empty?
            record['metadata']['support_links'].each do |sup|
              next unless ['Mailing list', 'Support email', 'Contact form'].include?(sup['type'])

              response.score = 'pass'
              break
            end
          end
        end
        if response.score == 'pass'
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource provides contact information.'
        else
          response.comments << 'Using FAIRsharing metadata for the record under evaluation, the resource does not provide contact information.'
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
