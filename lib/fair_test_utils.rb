require 'httparty'
require 'simple_doi'
require 'json'
require 'nokogiri'
require 'dotenv/load'
require 'cgi'
require 'uri'

# Utility functions common to all FAIR tests.
module FairTestUtils

  def metadata_harvesting(url)
    json_headers = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
    champion_url = 'https://tools.ostrails.eu/champion/harvest_only'
    response = HTTParty.post(champion_url,
                             body: { resource_identifier: url }.to_json,
                             headers: json_headers
    )
    body = response.body.to_s.strip
    return nil if body.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    nil
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

  # Recursively traverse a parsed JSON-LD structure and return prov:value's @value.
  def find_prov_value(obj)
    case obj
    when Hash
      prov_value = obj['prov:value'] || obj[:'prov:value']
      if prov_value.is_a?(Hash)
        value = prov_value['@value'] || prov_value[:'@value']
        return value unless value.nil?
      end

      obj.each_value do |value|
        result = find_prov_value(value)
        return result unless result.nil?
      end

      nil
    when Array
      obj.each do |item|
        result = find_prov_value(item)
        return result unless result.nil?
      end

      nil
    else
      nil
    end
  end

end
