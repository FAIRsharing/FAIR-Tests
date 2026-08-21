# frozen_string_literal: true

module FtF4MMetaIndexed
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f4_m_meta_indexed(url_record)
    record = request_jsonld(url_record)

    meta = {
      testid: 'FtF4MMetaIndexed.ttl',
      testname: 'FAIR Test – F4 – Metadata - indexed in a searchable resource',
      description: 'This test evaluates whether the provided identifier’s metadata is discoverable by performing public, automated searches with commonly-used search engines. The evaluation assesses whether a search service can successfully locate the metadata record using either the metadata identifier or landing page content such as the record title or keywords - both commonly consumed by search engines - thereby confirming that the resource has been appropriately indexed and is accessible for automated discovery. The expected input is the URL of a resource, and the test will pass if references to that input or identifiers contained within it are found when searching Datacite, core.ac.uk or SearXNG.',
      keywords: ['FAIR', 'F4', 'FAIRsharing', 'searchable', 'indexed'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/10.25504/FAIRsharing.fe8b9b', # Principle: https://fairsharing.org/6278
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f4_m_meta_indexed',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f4_m_meta_indexed/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta
    )

    if record && !record.empty?
      # Get any identifiers in the record.
      identifiers = find_schema_object_values(record, 'identifier').flat_map do |identifier|
        if identifier.is_a?(Hash)
          values = schema_object_values(identifier, 'value') +
                   schema_object_values(identifier, 'url')
          values.empty? ? jsonld_scalar_values(identifier) : values
        else
          identifier
        end
      end.uniq
      dois, non_dois = identifiers.partition do |identifier|
        is_doi?(identifier.to_s.dup)
      end

      # If any identifiers are DOIs look them up with Datacite to see if a matching entity is found (check name/title).
      dois.each do |identifier|
        found = request_datacite(identifier)
        next unless found

        found['titles'].each do |title|
          if title['title'].downcase == record.name.downcase
            response.score = 'pass'
            response.comments << 'This record was located by checking a DOI with Datacite.'
          end
        end
      end

      # Check with core.ac.uk/services/api by searching with the title.
      # N.B. https://core.ac.uk/acknowledge - find best way to do this...
      # TODO: An example needs to be found of a record which can be located here.
      core_data, core_code = search_core(record.name)
      if core_code != 200
        response.comments << "An attempt to search core.ac.uk failed: #{core_code}."
      elsif core_data
        response.score = 'pass'
        response.comments << 'This record was located by searching for its title with core.ac.uk.'
      end

      # Check by using the URL (and perhaps title?) with SearXNG.
      searxng_check, searxng_code = search_searxng(record.name)
      if searxng_code != 200
        response.comments << "A search with SearXNG failed: #{searxng_code}."
      elsif searxng_check
        searxng_check['results'].each do |res|
          if res['title'].downcase == record.name.downcase
            response.score = 'pass'
            response.comments << 'This record was located by searching for its title via a general web search (SearXNG).'
            break
          end
        end
      end

      # Default result if no pass scored above
      unless response.score == 'pass'
        response.score = 'fail'
        response.comments << 'No references to this identifier were found by any search attempted.'
      end
    else
      response.score = 'indeterminate'
      response.comments << 'No record was found matching the provided identifier.'
    end

    response.createEvaluationResponse
  end
end
