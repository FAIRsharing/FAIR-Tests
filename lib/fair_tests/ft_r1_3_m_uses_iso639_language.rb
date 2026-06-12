# frozen_string_literal: true
module FtR13MUsesIso639Language
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_3_m_uses_iso639_language(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'FT_R1.3_M_UsesISO639.ttl',
      testname: 'FAIR Test – R1.3 - Metadata – use of ISO 639 language', # FM:R1.3:M:UseISO639
      description: 'This test evaluates whether the metadata for the digital object includes at least one resolvable language attribute defined by the ISO 639 standard. It evaluates the value held in the language field against the official ISO 639 registry, searching for a valid, standardised code (specifically 639-2 / 639:2023) or a URI pointing to an ISO term.',
      keywords: %w[FAIR R1.3 ISO639],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8019',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_uses_iso639_language',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_uses_iso639_language/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      pass = false
      record['@graph'][0]['local:triples'].each do |triple|
        next unless triple.has_key?('@type')

        if triple['@type'].include?('http://schema.org/Language')
          next unless triple.has_key?('http://schema.org/sameAs')

          triple['http://schema.org/sameAs'].each do |sameAs|
            next unless sameAs.is_a?(Hash) && sameAs.has_key?('@id')

            if sameAs['@id'].downcase.include?('id.loc.gov/vocabulary/iso639')
              pass = true
              break
            end
          end
        end
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains a language attribute defined by the ISO 639 standard.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain a language attribute defined by the ISO 639 standard.'
      end
    end

    response.createEvaluationResponse

  end
end


