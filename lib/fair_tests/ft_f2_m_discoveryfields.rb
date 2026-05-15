module FtF2MDiscoveryfields
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  # Fields matching or similar to these will be selected.
  @@required_fields = %w(title contributors contributor_names summary abstract description)

  def ft_f2_m_discoveryfields(url_record)
    # 1. If a DOI, get metadata from Datacite.
    # 2. Run tests.
    # 3. If fail, try content negotation.
    # 4. Run tests again.
    # 5. If not DOI, try content negotation.

    # SimpleDOI may mutate the passed string, so keep an immutable copy.
    original_url = url_record&.dup

    meta = {
      testid: 'ft_f2_m_discoveryfields',
      testname: 'FAIR Test - F2 - Metadata - Discovery-Oriented Metadata Fields',
      description: "FAIR Test - F2 - Metadata - Discovery-Oriented Metadata Fields evaluates whether a metadata record includes a core set of mandatory descriptive elements that are essential for basic discovery. Specifically, it checks the resolved metadata for the presence of the following four fields: title, contributor names, summary/abstract/description, and publication date (defined as the date the record was first made publicly available). To pass, all of these fields must be present and populated within a structured, common format such as schema.org JSON-LD, DataCite XML, or Dublin Core XML. If any of these fields are empty, the evaluation is expected to fail.",
      keywords: ['FAIR', 'F2', 'discovery metadata'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://doi.org/10.25504/FAIRsharing.82c497',
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
        response = perform_ft_f2_m_discoveryfields(record, response)
        # Datacite data passed test.
        if response.score == 'pass'
          return response.createEvaluationResponse
        else
          # If DOI metadata fails, resolve DOI and test the resolved target.
          real_url = resolve_doi(original_url)
          record = metadata_harvesting(real_url)
          if record && !record.empty?
            response = perform_ft_f2_m_discoveryfields(record, response)
            return response.createEvaluationResponse
          end
        end
        return response.createEvaluationResponse
      else # Try content negotiation
        real_url = resolve_doi(original_url)
        record = metadata_harvesting(real_url)
        if record && !record.empty?
          response = perform_ft_f2_m_discoveryfields(record, response)
          return response.createEvaluationResponse
        end
      end
    else # Try content negotiation
      record = metadata_harvesting(url_record)
      if record && !record.empty?
        response = perform_ft_f2_m_discoveryfields(record, response)
        return response.createEvaluationResponse
      end
    end

    response.createEvaluationResponse
  end

  # This method will perform the actual tests to avoid repetition above.
  def perform_ft_f2_m_discoveryfields(record, response)
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
