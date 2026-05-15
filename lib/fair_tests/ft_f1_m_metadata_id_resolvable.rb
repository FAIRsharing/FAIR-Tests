module FtF1MMetadataIdResolvable
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f1_m_metadata_id_resolvable(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'ft_f1_m_metadata_id_resolvable',
      testname: 'https://fairsharing.org/8203',
      description: "",
      keywords: ['FAIR', 'F1', 'GUID', 'resolvable identifiers'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: '',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: "fair-tests.fairsharing.org",
      basePath: "test"
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      if doi_or_ark_present?(record)
        response.score = 'pass'
        response.comments << 'This record contains either a DOI or ARK identifier.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain either a DOI or ARK identifier.'
      end

    end

  end

  # TODO: Move all this to fair_test_utils, if needed.
  require 'uri'

  def doi_or_ark_present?(obj)
    case obj
    when Hash
      ids = obj['identifier']
      return ids.any? { |i| valid_identifier_url?(i) } if ids.is_a?(Array)
      obj.values.any? { |v| doi_or_ark_present?(v) }
    when Array
      obj.any? { |v| doi_or_ark_present?(v) }
    else
      false
    end
  end

  def valid_identifier_url?(h)
    return false unless
      (h['propertyID'] == 'DOI' && h['url'].start_with?('https://doi.org/')) ||
      (h['propertyID'] == 'ARK' && h['url'].start_with?('https://n2t.net/ark:'))

    uri = URI.parse(h['url'].to_s)
    uri.is_a?(URI::HTTP) && uri.host
  rescue URI::InvalidURIError
    false
  end
end