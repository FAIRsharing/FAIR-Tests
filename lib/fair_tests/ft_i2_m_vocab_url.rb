# frozen_string_literal: true

module FtI2MVocabUrl
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_i2_m_vocab_url(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'Ft_I2_M_VocabUrl.ttl',
      testname: 'FAIR Test - I2 - Metadata - Vocabulary URL',
      description: "This test evaluates whether the metadata for the digital object includes an inLanguage attribute containing a well-formed vocabulary URL. The expected input is the URL of the resource to be tested.",
      keywords: ['FAIR', 'F2', 'FAIR vocabulary'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/10.25504/FAIRsharing.0273a2',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_i2_m_vocab_url',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_i2_m_vocab_url/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      # Example data:
      # "inLanguage": [
      #     {
      #       "@type": "Language",
      #       "name": "English",
      #       "alternateName": "eng",
      #       "sameAs": "http://id.loc.gov/vocabulary/iso639-2/eng"
      #     }
      #   ],
      # See: https://github.com/FAIRsharing/FAIR-Tests/issues/117
      # There may be other tag types in future.
      languages = find_schema_object_values(record, 'inLanguage')
      vocabulary_url_present = languages.any? do |language|
        find_schema_object_values(language, 'sameAs').any? do |same_as|
          jsonld_scalar_values(same_as).any? { |value| valid_url?(value) }
        end
      end

      if vocabulary_url_present
        response.score = 'pass'
        response.comments << 'This record contains a language vocabulary URL.'
      else
        response.score = 'fail'
        response.comments << 'This record does not contain a language vocabulary URL.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record matching the provided identifier was found.'
    end

    response.createEvaluationResponse

  end
end
