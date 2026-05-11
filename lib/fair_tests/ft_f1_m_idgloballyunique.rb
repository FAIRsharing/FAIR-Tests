module FtF1MIdgloballyunique
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f1_m_idgloballyunique(url_record)
    records = find_by_regex(url_record)['records']

    meta = {
      testid: 'ft_f1_m_idgloballyunique',
      testname: 'FAIR Test - F1 - Metadata - evaluate identifier global uniqueness',
      description: "F1 requires that metadata be assigned a globally unique, persistent and resolvable identifier. This test is particularly concerned with the globally uniqueness aspect of GUPRIs; global uniqueness is required to prevent identifier collision across institutions, systems and domains. Otherwise, an identifier shared by multiple resources will confound efforts to describe that resource, or to use the identifier to retrieve it. In this test, the definition of global uniqueness follows the FAIRsharing guidance on Globally Unique, Persistent and Resolvable Identifier (GUPRI) schemas. The identifier being evaluated is checked for a match (using regular expressions) to an existing id schema within FAIRsharing. Pass: There is an id_schema record matching the regular expression that has the globally unique field set to 'true'. Indeterminate: No matching records were found in FAIRsharing. Fail: No indication of this resource having a globally unique identifier was found.",
      keywords: ['FAIR', 'A2', 'GUPRI', 'globally unique identifiers'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: '', # TODO: Add FAIRsharing metric for this test.
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


    # Regex match found.
    if records.length.positive?
      pass = false

      records.each do |r|
        next unless r['metadata']['globally_unique'] && !pass

        pass = true
      end

      if pass
        response.score = 'pass'
        response.comments << 'Using FAIRsharing metadata for the record under evaluation, this record has a globally unique identifier.'
      else
        response.score = 'fail'
        response.comments << 'No indication of this resource having a globally unique identifier was found.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No FAIRsharing identifier schema record found that matches the provided identifier.'
    end

    response.createEvaluationResponse
  end

end
