module FtF2MDiscoverytags
  require_relative '../fair_test_utils'
  include FairTestUtils

  # Tags matching or similar to these will be selected.
  @@required_fields = %w(tag keyword subject domain)

  def ft_f2_m_discoverytags(url_record)
    # 1. If a DOI, get metadata from Datacite.
    # 2. Run tests.
    # 3. If fail, try metadata harvesting.
    # 4. Run tests again.
    # 5. If not DOI, try metadata harvesting.

    # SimpleDOI may mutate the passed string, so keep an immutable copy.
    original_url = url_record&.dup

    meta = {
      testid: 'ft_f2_m_discoverytags',
      testname: 'FAIR Test - F2 - Metadata - Tagging To Aid Discovery',
      description: "FAIR Test - F2 - Metadata - Tagging To Aid Discovery evaluates the metadata for the presence of at least one keyword or tag of any kind (free-text or controlled). With regards to Findability (as opposed to e.g., Interoperability), the presence of any type of tag (irrespective of whether that tag is part of a controlled vocabulary) is the key feature for this metric. The metric expects the identifier to point to structured metadata (e.g., schema.org, DataCite, or DC) and verifies that the keyword/subject property is not empty. The metric passes if at least one tag is identified and fails if the keyword attribute is missing or null.",
      keywords: ['FAIR', 'F2', 'metadata discovery'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8021',
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


    # Attempt to load the record and, when data rare obtained
    if is_doi?(url_record)
      # Attempt to get metadata from Datacite.
      record = get_doi_metadata(url_record)
      if record && !record.empty? && !record.is_a?(String)
        response = perform_ft_f2_m_discoverytags(record, response)
        # Datacite data passed test.
        if response.score == 'pass'
          return response.createEvaluationResponse
        else
          # If DOI metadata fails, resolve DOI and test the resolved target.
          real_url = resolve_doi(original_url)
          record = metadata_harvesting(real_url)
          if record && !record.empty?
            response = perform_ft_f2_m_discoverytags(record, response)
            return response.createEvaluationResponse
          end
        end
        return response.createEvaluationResponse
      else # Try metadata harvesting
        real_url = resolve_doi(original_url)
        record = metadata_harvesting(real_url)
        if record && !record.empty?
          response = perform_ft_f2_m_discoverytags(record, response)
          return response.createEvaluationResponse
        end
      end
    else # Try metadata harvesting
      record = metadata_harvesting(url_record)
      if record && !record.empty?
        response = perform_ft_f2_m_discoverytags(record, response)
        return response.createEvaluationResponse
      end
    end

    response.createEvaluationResponse
  end

  # This method will perform the actual tests to avoid repetition above.
  def perform_ft_f2_m_discoverytags(record, response)
    if has_matching_key_with_value?(record, @@required_fields)
      response.score = 'pass'
      response.comments << "The record contains at least one of the required fields: #{@@required_fields.join(', ')}."
    else
      response.score = 'fail'
      response.comments << "The record does not contain at least one of the required fields: #{@@required_fields.join(', ')}."
    end

    response
  end

end
