module FtF2MDiscoveryfields
  require_relative '../fair_test_utils'
  include FairTestUtils

  @@required_fields = %w(title contributors contributor_names summary abstract description)
  def ft_f2_m_discoveryfields(url_record)
    # 1. If a DOI, get metadata from Datacite.
    # 2. Run tests.
    # 3. If fail, try content negotation.
    # 4. Run tests again.
    # 5. If not DOI, try content negotation.

    puts "Got record: #{url_record}"
    original_url = url_record

    data_test = {
      test_title_short: 'FAIR Test - F2 - Metadata - Discovery-Oriented Metadata Fields',
      test_title: 'Output from running test: FM:F2:M:DiscoveryFields (https://doi.org/10.25504/FAIRsharing.82c497)',
      test_id: 'TBC', # TODO
      description: '',
      endpointDescription: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f2_m_discover_oriented_metadata_fields/api',
      endpointURL: 'https://fair-tests.fairsharing.org/test/ft_f2_m_discover_oriented_metadata_fields',
      url_record: url_record
    }

    response = fair_test_response_basics(data_test)
    response[:value] = 'indeterminate'
    response[:description] = 'No record was found matching the provided identifier.'

    # Attempt to load the record and, when data rare obtained
    if is_doi?(url_record)
      # Attempt to get metadata from Datacite.
      record = get_doi_metadata(url_record)
      if record && !record.empty?
        response = perform_test(record, response)
        # Datacite data passed test.
        if response[:value] == 'pass'
          return response
        else
          # Content negotiation, try test again.
          record = content_negotiation(url_record)
          if record && !record.empty?
            return perform_test(record, response)
          end
        end
      else # Try content negotiation
        puts "Resolving DOI #{original_url}"
        real_url = resolve_doi(original_url)
        puts "Content negotiation for #{real_url}"
        record = content_negotiation(real_url)
        if record && !record.empty?
          return perform_test(record, response)
        end
      end
    else # Try content negotiation
      real_url = resolve_doi(url_record)
      record = content_negotiation(real_url)
      if record && !record.empty?
        return perform_test(record, response)
      end
    end

    response
  end

  # This method will perform the actual tests to avoid repetition above.
  def perform_test(record, response)
    # TODO: Perform the various tests here.
    pass = false
    record.keys.each do |key|
      if @@required_fields.include?(key)
        if record[key]
          response[:value] = 'pass'
          response[:description] = "The record contains at least one of the required fields: #{@@required_fields.join(', ')}."
          pass = true
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

__END__
      if record['registry'] == 'Database'
        if record['metadata'].include?('data_preservation_policy') && record['metadata']['data_preservation_policy'].include?('url') && !record['metadata']['data_preservation_policy']['url'].strip.empty?
          response[:value] = 'pass'
          response[:description] = "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database has a data preservation policy."
        else
          response[:value] = 'fail'
          response[:description] = "Using FAIRsharing metadata for the database under evaluation (https://fairsharing.org/#{record['id']}), the database does not have a data preservation policy."
        end
      else
        response[:value] = 'fail'
        response[:description] = "The record exists in FAIRsharing (https://fairsharing.org/#{record['id']}) but it is not a database."
      end