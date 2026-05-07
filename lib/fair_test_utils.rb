require 'httparty'
require 'simple_doi'
require 'json'
require 'nokogiri'
require 'dotenv/load'
require 'cgi'
require 'uri'

# Utility functions common to all FAIR tests.
module FairTestUtils

  def fair_test_response_basics(test_data)
    response = {}
    response['@context'] = "https://w3id.org/ftr/context"
    response['@id'] = "urn:fairsharing:#{SecureRandom.uuid}"
    response['@type'] = "https://w3id.org/ftr#TestResult"
    response[:identifier] = response['@id']
    response[:title] = test_data[:test_title]
    response[:license] = {
      '@id': 'https://fairsharing.org/licence'
    }
    response[:completion] = {
      '@value': 100
    }
    response[:assessmentTarget] = {
      '@id': test_data[:url_record]
    }
    response[:outputFromTest] = {
      '@id': test_data[:test_id],
      '@type': 'Test'
    }
    response[:generatedAtTime] = {
      '@type': 'http://www.w3.org/2001/XMLSchema#date',
      '@value': DateTime.now.to_s
    }
    response[:wasGeneratedBy] = {
      '@type': 'TestExecutionActivity',
      used: {
        '@id': test_data[:url_record]
      },
      wasAssociatedWith: {
        '@id': test_data[:test_id],
        identifier: test_data[:test_id],
        title: test_data[:test_title_short],
        description: test_data[:description],
        endpointDescription: {
          '@id': test_data[:endpointDescription]
        },
        endpointURL: {
          '@id': test_data[:endpointURL]
        }
      }
    }
    response
  end

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
    response
  end

  def content_negotiation(url)
    return {} if url.nil? || url.empty?

    # TODO: This assumes that there's JSON data available.
    # TODO: Better content negotation needed (Mark's tool?)
    json_headers = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
    jsonld_headers = {
      'Accept' => 'application/ld+json',
      'Content-Type' => 'application/ld+json'
    }

    # Try LD+JSON first
    response = HTTParty.get(url, headers: jsonld_headers)
    body = JSON.parse(response.body)

    unless body && body['@context'] == 'https://schema.org'
      response = HTTParty.get(url, headers: json_headers)
      body = JSON.parse(response.body)
    end
    #status = response.code,
    #message = response.message

    body
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
        #:nocov:
        nil
        #:nocov:
      end

      if !resolved.nil? && !resolved.empty?
        resolved_host = begin
          URI.parse(resolved).host.to_s.downcase
        rescue URI::InvalidURIError
          #:nocov:
          nil
          #:nocov:
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
    #:nocov:
    nil
    #:nocov:
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
        #:nocov:
        {}
        #:nocov:
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

  # The purpose of this function is to flip out and recursively traverse a hash in order to find any keys where
  # the value is a non-empty array.
  def find_keys_with_non_empty_values(obj, results = [], path = [])
    case obj
    when Hash
      obj.each do |key, value|
        current_path = path + [key]

        # Check if the value is a non-empty array
        if value.is_a?(Array) && !value.empty?
          results << current_path
        end

        if value.is_a?(String) && !value.empty?
          results << current_path
        end

        # Recurse into nested structures
        find_keys_with_non_empty_values(value, results, current_path)
      end

    when Array
      obj.each_with_index do |item, index|
        find_keys_with_non_empty_values(item, results, path + [index])
      end
    else
      return []
    end

    results.flatten
  end

end
