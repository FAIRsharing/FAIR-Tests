module FtF2MDiscoveryfields
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

    data_test = {
      test_title_short: 'FAIR Test - F2 - Metadata - Discovery-Oriented Metadata Fields',
      test_title: 'Output from running test: FM:F2:M:DiscoveryFields (https://doi.org/10.25504/FAIRsharing.82c497)',
      test_id: 'https://ostrails.github.io/assessment-component-metadata-records/test/FT_F2_M_Discoveryfields.ttl',
      description: 'FAIR Test - F2 - Metadata - Discovery-Oriented Metadata Fields evaluates whether a metadata record includes a core set of mandatory descriptive elements that are essential for basic discovery. Specifically, it checks the resolved metadata for the presence of the following four fields: title, contributor names, summary/abstract/description, and publication date (defined as the date the record was first made publicly available). To pass, all of these fields must be present and populated within a structured, common format such as schema.org JSON-LD, DataCite XML, or Dublin Core XML. If any of these fields are empty, the evaluation is expected to fail.',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f2_m_discoveryfields/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_f2_m_discoveryfields',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)
    response[:value] = 'indeterminate'
    response[:description] = 'No record was found matching the provided identifier.'

    # Attempt to load the record and, when data rare obtained
    if is_doi?(url_record)
      # Attempt to get metadata from Datacite.
      record = get_doi_metadata(url_record)
      if record && !record.empty? && !record.is_a?(String)
        response = perform_ft_f2_m_discoveryfields(record, response)
        # Datacite data passed test.
        if response[:value] == 'pass'
          return response
        else
          # If DOI metadata fails, resolve DOI and test the resolved target.
          real_url = resolve_doi(original_url)
          record = content_negotiation(real_url)
          if record && !record.empty?
            return perform_ft_f2_m_discoveryfields(record, response)
          end
        end
        return response
      else # Try content negotiation
        real_url = resolve_doi(original_url)
        record = content_negotiation(real_url)
        if record && !record.empty?
          return perform_ft_f2_m_discoveryfields(record, response)
        end
      end
    else # Try content negotiation
      real_url = resolve_doi(url_record)
      record = content_negotiation(real_url)
      if record && !record.empty?
        return perform_ft_f2_m_discoveryfields(record, response)
      end
    end

    response
  end

  # This method will perform the actual tests to avoid repetition above.
  def perform_ft_f2_m_discoveryfields(record, response)
    pass = false
    keys = find_keys_with_non_empty_values(record)
    keys.each do |key|
      if @@required_fields.to_s.include?(key)
        response[:value] = 'pass'
        response[:description] = "The record contains at least one of the required fields: #{@@required_fields.join(', ')}."
        pass = true
      else
        @@required_fields.each do |field|
          if field.to_s.include?(key) || key.include?(field)
            response[:value] = 'pass'
            response[:description] = "The record contains at least one of the required fields: #{@@required_fields.join(', ')}."
            pass = true
          end
        end
      end
    end
    unless pass
      response[:value] = 'fail'
      response[:description] = "The record does not contain at least one of the required fields: #{@@required_fields.join(', ')}."
    end

    response
  end

end
