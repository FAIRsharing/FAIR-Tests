# frozen_string_literal: true
module FtR11MFsUsageLicences
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_1_m_fs_usage_licences(url_record)
    if url_record.include? 'doi.org'
      record = get_fairsharing_record(resolve_doi(url_record))
    else
      record = get_fairsharing_record(url_record)
    end

    meta = {
      testid: 'FT_R1_1_M_Fs_UsageLicences.ttl',
      testname: 'FAIR Test - R1.1 - Metadata - Resource declares a usage licence',
      description: "R1.1 requires that (meta)data are released with a clear and accessible usage licence. This metric uses the structured metadata provided within FAIRsharing records to determine whether the resource declares one or more usage licences. This test evaluates whether the database, standard or policy resource declares a usage licence. In FAIRsharing, this corresponds to the presence of one or more usage licences associated with the resource. Expected input is the DOI or URL of the registry (e.g. FAIRsharing) record under evaluation.",
      keywords: %w[FAIR R.1.1 licences],
      creator: 'https://orcid.org/0000-0001-9572-0972',
      indicators: [],
      metric: 'https://fairsharing.org/8801',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_1_m_fs_usage_licences',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_1_m_fs_usage_licences/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
      )


    if record
      if record['registry'] == 'Database'
        pass = false
        licenceLinks = record['licenceLinks'] || record.dig('metadata', 'licenceLinks') || []
        unless licenceLinks.empty?

          pass = licenceLinks.any? do |licence|
            next false unless licence['relation'] == 'applies_to_content'

            true
          end
        end
        if pass
          response.score = 'pass'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database declares a usage licence.'
        else
          response.score = 'fail'
          response.comments << 'Using FAIRsharing metadata for the database under evaluation, the database does not declare a usage licence.'
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
