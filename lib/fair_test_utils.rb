require 'httparty'
require 'simple_doi'
require 'json'
require 'nokogiri'
require 'dotenv/load'
require 'cgi'
require 'digest'
require 'fileutils'
require 'tempfile'
require 'uri'
require 'ftr_ruby'

# Utility functions common to all FAIR tests.
module FairTestUtils
  CACHE_DIRECTORY = File.expand_path('../cache', __dir__)
  CACHE_ENABLED_VALUES = %w[1 true yes on].freeze
  FAIRSHARING_CACHE_TTL = 86_400
  ORA_CACHE_TTL = 86_400
  FAIRSHARING_USER_AGENT = 'FAIRsharing FAIR-Tests server'

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
    return fetch_jsonld(url) unless ora_record_url?(url) && ora_cache_enabled?

    cache_path = ora_cache_path(url)
    cached_record = read_ora_cache(cache_path)
    return cached_record unless cached_record.nil?

    with_ora_cache_lock(cache_path) do
      cached_record = read_ora_cache(cache_path)
      return cached_record unless cached_record.nil?

      record = fetch_jsonld(url, require_success: true)
      write_ora_cache(cache_path, record) if cacheable_ora_record?(record)
      record
    end
  end

  def fetch_jsonld(url, require_success: false)
    json_headers = {
      'Accept' => 'application/ld+json',
      'Content-Type' => 'application/ld+json'
    }
    response = HTTParty.get(url, headers: json_headers)
    return nil if require_success && !response.success?

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

  def funding_defined?(record)
    funding = record['funding']

    funding.is_a?(Array) && funding.any? do |funding_entry|
      funding_entry.is_a?(Hash) && funding_value_present?(funding_entry)
    end
  end

  def funding_value_present?(value)
    case value
    when Hash
      value.values.any? { |nested_value| funding_value_present?(nested_value) }
    when Array
      value.any? { |nested_value| funding_value_present?(nested_value) }
    else
      contains_meaningful_value?(value)
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
    return fetch_fairsharing_record_from_api(id) unless fairsharing_cache_enabled?

    cache_path = fairsharing_cache_path(id)
    cached_record = read_fairsharing_cache(cache_path)
    return cached_record unless cached_record.nil?

    with_fairsharing_cache_lock(cache_path) do
      cached_record = read_fairsharing_cache(cache_path)
      return cached_record unless cached_record.nil?

      record = fetch_fairsharing_record_from_api(id)
      write_fairsharing_cache(cache_path, record) if cacheable_fairsharing_record?(record)
      record
    end
  end

  def fairsharing_cache_enabled?
    value = ENV.fetch('FAIRSHARING_CACHE_ENABLED', 'true').to_s.downcase
    CACHE_ENABLED_VALUES.include?(value)
  end

  def fairsharing_cache_directory
    File.join(cache_directory('FAIRSHARING_CACHE_DIR'), 'fairsharing')
  end

  def fairsharing_cache_ttl
    configured_ttl = Integer(ENV.fetch('FAIRSHARING_CACHE_TTL', FAIRSHARING_CACHE_TTL.to_s), 10)
    configured_ttl.positive? ? configured_ttl : FAIRSHARING_CACHE_TTL
  rescue ArgumentError, TypeError
    FAIRSHARING_CACHE_TTL
  end

  def fairsharing_cache_key(id)
    identifier = CGI.unescape(id.to_s.strip).sub(%r{/+\z}, '')
    fairsharing_id = identifier.match(
      %r{(?:\A|/)(?:10\.25504/)?fairsharing\.([a-z0-9_-]+)\z}i
    )
    return "fairsharing.#{fairsharing_id[1].downcase}" if fairsharing_id

    numeric_id = identifier.match(%r{(?:\A|fairsharing\.org/)(\d+)\z}i)
    return numeric_id[1] if numeric_id

    "identifier-#{Digest::SHA256.hexdigest(identifier)}"
  end

  def fairsharing_cache_path(id)
    File.join(fairsharing_cache_directory, "#{fairsharing_cache_key(id)}.json")
  end

  def read_fairsharing_cache(cache_path)
    read_json_cache(cache_path, fairsharing_cache_ttl, 'FAIRsharing') do |record|
      cacheable_fairsharing_record?(record)
    end
  end

  def write_fairsharing_cache(cache_path, record)
    write_json_cache(cache_path, record, 'FAIRsharing')
  end

  # A lock is required as there are multiple Puma threads accessing these files.
  def with_fairsharing_cache_lock(cache_path, &block)
    with_cache_lock(cache_path, 'FAIRsharing', &block)
  end

  def cacheable_fairsharing_record?(record)
    record.is_a?(Hash) && !record.empty? && !record.key?(:message) && !record.key?('message')
  end

  def ora_cache_enabled?
    value = ENV.fetch('ORA_CACHE_ENABLED', 'true').to_s.downcase
    CACHE_ENABLED_VALUES.include?(value)
  end

  def ora_cache_directory
    File.join(cache_directory('ORA_CACHE_DIR'), 'ora')
  end

  def ora_cache_ttl
    configured_ttl = Integer(ENV.fetch('ORA_CACHE_TTL', ORA_CACHE_TTL.to_s), 10)
    configured_ttl.positive? ? configured_ttl : ORA_CACHE_TTL
  rescue ArgumentError, TypeError
    ORA_CACHE_TTL
  end

  def ora_record_url?(url)
    !ora_record_identifier(url).nil?
  end

  def ora_record_identifier(url)
    uri = URI.parse(url.to_s.strip)
    return nil unless uri.scheme&.downcase == 'https' && uri.host&.downcase == 'ora.ox.ac.uk'

    match = CGI.unescape(uri.path).match(%r{\A/objects/uuid:([^/]+)/?\z}i)
    match && match[1]
  rescue URI::InvalidURIError
    nil
  end

  def ora_cache_key(url)
    identifier = ora_record_identifier(url)
    if identifier&.match?(/\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/i)
      identifier.downcase
    else
      "identifier-#{Digest::SHA256.hexdigest(url.to_s.strip)}"
    end
  end

  def ora_cache_path(url)
    File.join(ora_cache_directory, "#{ora_cache_key(url)}.json")
  end

  def read_ora_cache(cache_path)
    read_json_cache(cache_path, ora_cache_ttl, 'ORA') do |record|
      cacheable_ora_record?(record)
    end
  end

  def write_ora_cache(cache_path, record)
    write_json_cache(cache_path, record, 'ORA')
  end

  def with_ora_cache_lock(cache_path, &block)
    with_cache_lock(cache_path, 'ORA', &block)
  end

  def cacheable_ora_record?(record)
    (record.is_a?(Hash) || record.is_a?(Array)) && !record.empty?
  end

  def cache_directory(service_environment_variable)
    configured_directory = ENV.fetch(
      service_environment_variable,
      ENV.fetch('CACHE_DIR', CACHE_DIRECTORY)
    )
    File.expand_path(configured_directory, File.expand_path('..', __dir__))
  end

  def read_json_cache(cache_path, ttl, label)
    return nil unless File.file?(cache_path)
    return nil unless Time.now - File.mtime(cache_path) < ttl

    record = JSON.parse(File.read(cache_path))
    yield(record) ? record : nil
  rescue JSON::ParserError, SystemCallError => e
    warn "Could not read #{label} cache #{cache_path}: #{e.message}"
    nil
  end

  def write_json_cache(cache_path, record, label)
    FileUtils.mkdir_p(File.dirname(cache_path))
    temporary_file = Tempfile.new(
      [".#{File.basename(cache_path, '.json')}-", '.tmp'],
      File.dirname(cache_path)
    )
    temporary_file.write(JSON.generate(record))
    temporary_file.flush
    temporary_file.fsync
    temporary_file.close
    File.rename(temporary_file.path, cache_path)
  rescue JSON::GeneratorError, SystemCallError => e
    warn "Could not write #{label} cache #{cache_path}: #{e.message}"
  ensure
    temporary_file&.close!
  end

  def with_cache_lock(cache_path, label)
    lock_file = begin
      FileUtils.mkdir_p(File.dirname(cache_path))
      File.open("#{cache_path.delete_suffix('.json')}.lock", File::RDWR | File::CREAT, 0o644)
    rescue SystemCallError => e
      warn "Could not open #{label} cache lock for #{cache_path}: #{e.message}"
      return yield
    end

    begin
      lock_file.flock(File::LOCK_EX)
    rescue SystemCallError => e
      warn "Could not lock #{label} cache #{cache_path}: #{e.message}"
      lock_file.close
      return yield
    end

    begin
      yield
    ensure
      lock_file.flock(File::LOCK_UN)
      lock_file.close
    end
  end

  def fetch_fairsharing_record_from_api(id)
    headers = {
      'Content-Type' => 'application/json' ,
      'Accept' => 'application/json',
      'User-Agent' => FAIRSHARING_USER_AGENT,
      'X-GraphQL-Key' => ENV['FAIRSHARING_API_KEY']
    }
    query_string = %Q{
      query {
        fairsharingRecord(id: "#{id}"){
          name
          id
          subjects {
            id
            label
            ancestors {id label}
          }
          registry
          metadata
          countries { id }
          organisationLinks {
            relation
            grant { id }
          }
          licences { id }
          licenceLinks {
            relation
          }
          description
          recordAssociations {
            recordAssocLabel
            linkedRecord {
              id
              registry
              type
              metadata
            }
          }
          reverseRecordAssociations {
            recordAssocLabel
            fairsharingRecord {
              id
              type
            }
          }
         objectTypes {
          label
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
      rescue StandardError
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
      'User-Agent' => FAIRSHARING_USER_AGENT,
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

  # Method to check that it has the Life Science subject label or
  # there is at least one ancestor with that label
  def subject_has_ls_ancestor(subjects)
    subjects.each do |s|
      return true if s['label'] == 'Life Science'

      next unless s.include?('ancestors')

      s['ancestors'].each do |a|
        return true if a['label'] == 'Life Science'
      end
    end
    false
  end

  # Given a list of ids with subject ids ref_ids = [a,b,c...]
  # check if subjects [{'id': x, 'ancestors': [{'id':y},{id:z}]},{'id': w, 'ancestors': [{'id':m}]}....]
  # has an id or an ancestors that appears in ref_ids
  def subject_appears_or_descendent(ref_ids, subjects)
    subjects.each do |s|
      return true if ref_ids.include?(s['id'])

      next if s['ancestors'].nil? || s['ancestors'].empty?

      s['ancestors'].each do |s_a|
        return true if ref_ids.include?(s_a['id'])
      end
    end
    false
  end

end
