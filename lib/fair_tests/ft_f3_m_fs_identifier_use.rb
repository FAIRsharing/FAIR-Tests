# frozen_string_literal: true

module FtF3MFsIdentifierUse
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f3_m_fs_identifier_use(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'FT_F3_M_FsIdentifierUse.ttl',
      testname: 'FAIR Test - F3 - resource identifiers in FAIRsharing metadata',
      description: 'This test assesses whether the FAIRsharing record under evaluation contains both a FAIRsharing identifier (DOI or URL) and a homepage URL for the resource it describes. Expected input is the FAIRsharing DOI or URL for the FAIRsharing record under evaluation  or the homepage of the record it describes.',
      keywords: ['ARK', 'FAIR', 'F3', 'FAIRsharing', 'identifier'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8372',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f3_m_fs_identifier_use',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f3_m_fs_identifier_use/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      # This record should have a FAIRsharing URL (all records have this) or DOI.
      # This will _always_ pass.
      # Check that record['metadata']['doi'] exists and is a valid DOI. If it does not exist,
      # add a comment to the response but do not fail the test.
      doi = record.dig('metadata', 'doi').to_s.strip
      if doi.empty?
        response.comments << 'This record does not contain a FAIRsharing DOI.'
      elsif is_doi?(doi)
        response.comments << 'This record contains a valid FAIRsharing DOI.'
      else
        response.comments << 'This record contains an invalid FAIRsharing DOI.'
      end

      # Homepage is tested for, though it should also always be present.
      # Check that record['metadata']['homepage'] is present, is a valid URL, and returns a valid response
      # to an http HEAD check.
      begin
        homepage = record.dig('metadata', 'homepage').to_s
        uri = URI.parse(homepage)
        if homepage.empty? || !%w[http https].include?(uri.scheme)
          response.score = 'fail'
          response.comments << 'This record does not contain a valid homepage URL.'
        elsif HTTParty.head(homepage, timeout: 10, follow_redirects: true).success?
          response.score = 'pass'
          response.comments << 'This record contains a resolvable homepage URL.'
        else
          response.score = 'fail'
          response.comments << 'This record homepage URL did not resolve.'
        end
      rescue URI::InvalidURIError, Socket::ResolutionError, Net::OpenTimeout, Net::ReadTimeout
        response.score = 'fail'
        response.comments << 'This record does not contain a resolvable homepage URL.'
      end
    end

    response.createEvaluationResponse
  end
end
