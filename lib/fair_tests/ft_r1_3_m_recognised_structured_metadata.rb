module FtR13MRecognisedStructuredMetadata
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_r1_3_m_recognised_structured_metadata(url_record)
    record = metadata_harvesting(url_record)

    meta = {
      testid: 'FT_R1_3_M_UseStuctGenericFormat.ttl',
      testname: 'FAIR Test – R1.3 - Metadata – use of recognised and structured generic metadata format',
      description: 'This metric evaluates whether the dataset metadata is structured according to predefined, widely adopted metadata schemas appropriate to institutional repositories and other generalist contexts, such as schema.org (JSON-LD) or DataCite. It checks the record’s landing page for embedded or linked structured data that can be successfully parsed against the declared community schema. Finding JSON+LD or XML formats will result in a pass; otherwise, the test will fail.',
      keywords: ['FAIR', 'R1.3', 'recognised structured metadata'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8020',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_r1_3_m_recognised_structured_metadata',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_r1_3_m_recognised_structured_metadata/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    # Parse the harvester's logs to see if it finds data in an acceptable format.
    acceptable_formats = [
      'Found jsonld application/ld+json type of content',
      'Found xml text/xml type of content'
    ]
    pass = false
    if record && !record.empty?
      info = nil
      record['@graph'].each do |g|
        next unless g.has_key?('local:comments')

        info = g
      end
      info['local:comments'].each do |line|
        next unless line.include?('INFO')

        acceptable_formats.each do |format|
          next unless line.include?(format)

          pass = true
          response.score = 'pass'
          response.comments << 'Using the FAIR Champion metadata harvester evaluation, the record has a recognised structured metadata format.'
        end
      end

      unless pass
        response.score = 'fail'
        response.comments << 'Using the FAIR Champion metadata harvester evaluation, the record does not have a recognised structured metadata format.'
      end
    else
      response.comments << 'No record was found matching the provided identifier.'
    end

    response.createEvaluationResponse
  end

end
