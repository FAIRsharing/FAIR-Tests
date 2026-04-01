require 'httparty'
require 'simple_doi'
require 'json'
require 'nokogiri'

# Utility functions common to all FAIR tests.
module TestUtils

  def test_response_basics(test_data)
    response = {
      value: 'indeterminate',
      description: 'No record was found matching the provided GUID.'
    }
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

  def post_to_test(url)
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

    # TODO: Check if a DOI first and get metadata
    if url.include?('doi.org')
      # Get metadata from DOI. How?
    end

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

  # Convert XML to a hash.
  # This is used by get_doi_metadata, below.
  def xml_node_to_hash(node)
    children = node.element_children

    if children.empty?
      node.text.strip
    else
      hash = {}

      children.each do |child|
        value = xml_node_to_hash(child)

        if hash.key?(child.name)
          hash[child.name] = [hash[child.name]] unless hash[child.name].is_a?(Array)
          hash[child.name] << value
        else
          hash[child.name] = value
        end
      end

      hash
    end
  end

  # TODO:
  # This should be able to get JSON-formatted data from a DOI.
  # It may be that we replace this at a later date with Mark's system, or
  # incorporate code from that system instead (SimpleDOI is old...)
  def get_doi_metadata(url)
    json_data = {}
    doi = SimpleDOI::DOI.new(url)

    # Call lookup() and prefer JSON, but fallback to XML if unavailable
    response = doi.lookup [SimpleDOI::CITEPROC_JSON, SimpleDOI::UNIXREF_XML]

    # Check the response_content_type for parsing.
    begin
      if doi.response_content_type == SimpleDOI::CITEPROC_JSON
        json_data JSON.parse(response)
      else
        # Convert to JSON for easier processing.
        doc = Nokogiri::XML(response)
        json_data = xml_node_to_hash(doc.root)
      end
    rescue => e
      puts "Error parsing DOI metadata: #{e.message}"
    end
    json_data
  end

  # A simple means of resolving a DOI without having to use the simple_doi gem.
  def resolve_doi(url)
    response = HTTParty.get(url, timeout: 5)

    if response.success?
      response.request.last_uri.to_s
    else
      nil
    end
  rescue Net::OpenTimeout, Net::ReadTimeout
    nil
  end

end