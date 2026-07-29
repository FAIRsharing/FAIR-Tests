require 'httparty'
require 'simple_doi'
require 'json'
require 'nokogiri'
require 'dotenv/load'
require 'cgi'
require 'uri'
require 'ftr_ruby'

# Utility functions common to all FAIR tests.
module FairTestUtils
  # Deprecated 29/7/26 due to unreliability.
  #def metadata_harvesting(url)
  #  json_headers = {
  #    'Accept' => 'application/json',
  #    'Content-Type' => 'application/json'
  #  }
  #  champion_url = 'https://tools.ostrails.eu/champion/harvest_only'
  #  response = HTTParty.post(champion_url,
  #                           body: { resource_identifier: url }.to_json,
  #                           headers: json_headers
  #  )
  #
  #  body = response.body.to_s.strip
  #  return nil if body.empty?
  #
  #  JSON.parse(body)
  #rescue JSON::ParserError
  #  nil
  #end

  # Useful for getting records from ORA when the harvester is known to be unable to parse
  # the fields required.
  def request_jsonld(url)
    json_headers = {
      'Accept' => 'application/ld+json',
      'Content-Type' => 'application/ld+json'
    }
    response = HTTParty.get(url, headers: json_headers)

    body = response.body.to_s.strip
    return nil if body.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    nil
  end

  def request_xml(url)
    xml_headers = {
      'Accept' => 'text/xml',
      'Content-Type' => 'text/xml'
    }
    response = HTTParty.get(url, headers: xml_headers)

    body = response.body.to_s.strip
    return nil if body.empty?
    return nil unless valid_xml?(body)

    body
  rescue StandardError
    nil
  end

  def valid_xml?(value)
    return false unless value.is_a?(String) && !value.strip.empty?

    document = Nokogiri::XML(value) { |config| config.strict.nonet }
    !document.root.nil?
  rescue Nokogiri::XML::SyntaxError
    false
  end

  # Parse the data structure returned by metadata harvesting and look for particular keys.
  # Usage: has_matching_key_with_value?(data, %w[publisher publish])
  def has_matching_key_with_value?(obj, patterns)
    case obj
    when Hash
      obj.any? do |key, value|
        (
          patterns.any? { |p| key.to_s.downcase.include?(p.downcase) } &&
            contains_meaningful_value?(value)
        ) || has_matching_key_with_value?(value, patterns)
      end

    when Array
      obj.any? { |item| has_matching_key_with_value?(item, patterns) }

    else
      false
    end
  end

  # Necessary for the above function:
  # This code is to return true if a value from the data structure is not nil, empty etc.
  def contains_meaningful_value?(value)
    case value
    when nil
      false
    when String
      !value.strip.empty?
    when Numeric
      value != 0
    when Array, Hash
      !value.empty?
    else
      true
    end
  end

  def has_top_level_jsonld_discovery_field?(record, fields)
    return false unless record.is_a?(Hash)

    fields.any? do |field|
      [
        record[field],
        record[field.to_sym],
        record["schema:#{field}"],
        record["http://schema.org/#{field}"]
      ].any? { |value| contains_meaningful_value?(value) }
    end
  end



  # TODO:
  # This should be able to get JSON-formatted data from a DOI.
  # It may be that we replace this at a later date with Mark's system, or
  # incorporate code from that system instead (SimpleDOI is old...)
  def get_doi_metadata(url)
    json_data = {}
    doi = SimpleDOI::DOI.new(url)

    # Call lookup() and prefer JSON
    response = doi.lookup [SimpleDOI::CITEPROC_JSON]

    # Check the response_content_type for parsing.
    begin
      json_data = JSON.parse(response)
    rescue => e
      json_data[:error] = "Error parsing DOI metadata: #{e.message}"
    end
    json_data
  end

  # Check if a string is actually a DOI.
  def is_doi?(url)
    begin
      SimpleDOI::DOI.new(url)
    rescue ArgumentError
      return false
    end
    true
  end

  # A simple means of resolving a DOI without having to use the simple_doi gem.
  def resolve_doi(url)
    doi_url = normalize_doi_url(url)
    return nil if doi_url.nil? || doi_url.empty?

    response = HTTParty.get(doi_url, timeout: 5, follow_redirects: true)

    if response.success?
      body_url = extract_url_from_response_body(response.body)
      resolved = begin
        response.request.last_uri.to_s
      rescue Addressable::URI::InvalidURIError
        nil
      end

      if !resolved.nil? && !resolved.empty?
        resolved_host = begin
          URI.parse(resolved).host.to_s.downcase
        rescue URI::InvalidURIError
          nil
        end
        return body_url if resolved_host == 'doi.org' && !body_url.nil?
        return nil if resolved_host == 'doi.org'
        return resolved
      end

      return body_url unless body_url.nil?

      nil
    else
      nil
    end
  rescue Net::OpenTimeout, Net::ReadTimeout
    nil
  end

  def normalize_doi_url(url)
    return nil if url.nil?

    value = url.to_s.strip
    return nil if value.empty?

    doi = case value
          when %r{\Ahttps?://doi\.org/(.+)\z}i
            Regexp.last_match(1)
          when %r{\Adoi:(.+)\z}i
            Regexp.last_match(1)
          when %r{\A10\.\d{4,9}/\S+\z}i
            value
          else
            return value
          end

    "https://doi.org/#{CGI.escape(CGI.unescape(doi))}"
  end

  def extract_url_from_response_body(body)
    value = body.to_s.strip
    begin
      parsed_value = JSON.parse(value)
      value = parsed_value if parsed_value.is_a?(String)
    rescue JSON::ParserError
      # Keep raw body when it is not JSON.
    end

    value = value.to_s.strip
    return value if value.match?(%r{\Ahttps?://}i)

    nil
  end

  # This will look through the output of the metadata harvester and find all objects
  # that were in a hash element that the key matches val_keys based on property
  # For example, find_schema_object_values({"a1" :{"a2": [v1, v2]}, "a2": "text"}, "a2")
  # will return [[v1, v2], "text"]
  def find_schema_object_values(obj, property_name, results = [])
    val_keys = [
      property_name,
      "schema:#{property_name}",
      "http://schema.org/#{property_name}"
    ]
    case obj
    when Hash
      obj.each do |key, value|
        results << value if val_keys.to_s.downcase.include?(key.downcase)
        find_schema_object_values(value, property_name, results)
      end
    when Array
      obj.each do |item|
        find_schema_object_values(item, property_name, results)
      end
    end

    results.flatten
  end

  def schema_object_values(obj, property_name)
    return [] unless obj.is_a?(Hash)

    keys = [
      property_name,
      "schema:#{property_name}",
      "http://schema.org/#{property_name}"
    ]

    keys.flat_map do |key|
      [obj[key], obj[key.to_sym]]
    end.compact.flat_map do |value|
      jsonld_scalar_values(value)
    end
  end

  def jsonld_scalar_values(value)
    case value
    when Array
      value.flat_map { |item| jsonld_scalar_values(item) }
    when Hash
      scalar = value['@value'] || value[:'@value'] || value['@id'] || value[:'@id']
      scalar.nil? ? [] : [scalar]
    else
      value.nil? ? [] : [value]
    end
  end


  # This method will prepare a text string for getting a record from FAIRsharing, then fetch the record.
  def obtain_record_from_text(text_record)
    # Only accept FAIRsharing URLs
    if text_record.nil? || text_record.empty? ||
       !(text_record.include?('https://doi.org/10.25504') ||
         text_record.include?('https://fairsharing.org/10.25504') ||
         text_record.include?('fairsharing.org'))
      return nil
    end

    record = nil
    text_record = text_record.chop if text_record.end_with?('/')

    if text_record.include?('10.25504') || text_record.include?('//fairsharing.org/FAIRsharing')
      v = text_record.split('/')
      record = get_fairsharing_record("10.25504/#{v[-1]}")
    elsif text_record.include?('https://fairsharing.org') || text_record.include?('https://preview.fairsharing.org')
      v = text_record.split('/')
      record = get_fairsharing_record(v[-1].to_i)
    end
    record
  end

  # This will get a record from the FAIRsharing database via the API.
  # TODO: Currently the data are very extensive, but we may need only metadata and perhaps relations.
  def get_fairsharing_record(id)
    headers = {
      'Content-Type' => 'application/json' ,
      'Accept' => 'application/json',
      'X-GraphQL-Key' => ENV['FAIRSHARING_API_KEY']
    }
    query_string = %Q{
      query {
        fairsharingRecord(id: "#{id}"){
          name
          id
          subjects { id label }
          registry
          type
          metadata
          countries { id name }
          exhaustiveLicences
          domains { id label }
          taxonomies { id label }
          userDefinedTags { id label }
          organisations { id name }
          organisationLinks {
            id
            relation
            fairsharingRecord { id }
            organisation { id name }
            grant {id name}
            isLead
          }
          grants { id name }
          publications { id title }
          licences { id name }
          licenceLinks {
            relation
            licence { id name }
          }
          description
          createdAt
          updatedAt
          recordAssociations {
            recordAssocLabel
            recordAssocLabelId
            linkedRecord {
              name
              id
              registry
              type
              metadata
            }
          }
          reverseRecordAssociations {
            recordAssocLabel
            recordAssocLabelId
            fairsharingRecord {
              name
              id
              registry
              type
              metadata
            }
          }
         objectTypes {
          id
         }
         format
        }
      }
    }

    response = HTTParty.post(ENV['FAIRSHARING_API_URL'],
                             body: { query: query_string }.to_json,
                             headers: headers
    )


    if response.code == 200
      begin
        JSON.parse(response.body)['data']['fairsharingRecord']
      rescue
        {}
      end
    else
      {
        message: "Error getting record from FAIRsharing API: #{response.code}, #{response.message}",
      }
    end
  end

  #...and this one is for calling the find_matching_regex method on the FAIRsharing API.
  # It returns a hash with matches (the original regex matches) and records; these latter
  # are the full data of each record in the matches hash.
  def find_by_regex(url)
    headers = {
      'Content-Type' => 'application/json' ,
      'Accept' => 'application/json',
      'X-GraphQL-Key' => ENV['FAIRSHARING_API_KEY']
    }
    query_string = %Q{
      query {
        regex(term: "#{url}", secondary: true){
          records {
            name
            id
            metadata
          }
          matches
        }
      }
    }

    response = HTTParty.post(ENV['FAIRSHARING_API_URL'],
                             body: { query: query_string }.to_json,
                             headers: headers
    )

    if response.code == 200
      JSON.parse(response.body)['data']['regex']
    else
      {
        message: "Error getting record from FAIRsharing API: #{response.code}, #{response.message}",
      }
    end
  end

  def valid_url?(url)
    value = url.to_s.strip
    return false if value.empty?

    uri = URI.parse(value)
    %w[http https].include?(uri.scheme) && !uri.host.to_s.empty?
  rescue URI::InvalidURIError
    false
  end

  def valid_iso639_2_url?(value)
    return false unless valid_url?(value)

    uri = URI.parse(value.to_s.strip)
    uri.host.to_s.downcase == 'id.loc.gov' &&
      uri.path.match?(%r{\A/vocabulary/iso639-2/[a-z]{3}\z}i) &&
      uri.query.nil? &&
      uri.fragment.nil?
  end

  def valid_orcid_id?(value)
    orcid_id = value.to_s.strip
    return false unless orcid_id.match?(/\A\d{4}-\d{4}-\d{4}-\d{3}[\dX]\z/)

    digits = orcid_id.delete('-')
    total = digits[0, 15].each_char.reduce(0) do |sum, digit|
      (sum + digit.to_i) * 2
    end
    check_digit = (12 - (total % 11)) % 11
    expected = check_digit == 10 ? 'X' : check_digit.to_s

    digits[-1] == expected
  end

  def valid_ror_id?(value)
    value.to_s.strip.match?(/\A0[a-hj-km-np-tv-z0-9]{6}\d{2}\z/)
  end

  def valid_ror_url?(value)
    return false unless valid_url?(value)

    uri = URI.parse(value.to_s.strip)
    uri.scheme == 'https' &&
      uri.host.to_s.downcase == 'ror.org' &&
      valid_ror_id?(uri.path.delete_prefix('/')) &&
      uri.query.nil? &&
      uri.fragment.nil?
  end

end
