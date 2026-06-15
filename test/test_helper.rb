ENV['RACK_ENV'] = 'test'

require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/config/'
end

require 'minitest/autorun'
require 'rack/test'
require 'json/ld'
require_relative '../fair_tests'


module TestHelper
  include Rack::Test::Methods

  def app
    FairTests
  end

  TRIG_HEADERS = { 'Content-Type' => 'application/trig' }

  def stub_metadata_harvesting(response_body, resource_identifier: "https://example.org/records/abc123")
    body = trig_body_for(response_body, resource_identifier)
    clear_harvester_cache(resource_identifier)

    stub_request(:get, resource_identifier).
      to_return(status: 200, body: body, headers: TRIG_HEADERS)
  end

  def clear_harvester_cache(resource_identifier)
    [
      FAIRChampionHarvester::Utils::AcceptHeader,
      { "Accept" => FAIRChampionHarvester::Utils::XML_FORMATS["xml"].join(",") },
      { "Accept" => FAIRChampionHarvester::Utils::JSON_FORMATS["json"].join(",") },
      FAIRChampionHarvester::Utils::AcceptDefaultHeader
    ].each do |headers|
      cache_key = Digest::MD5.hexdigest(resource_identifier + headers.to_s)
      %w[head body uri error].each do |suffix|
        path = "/tmp/#{cache_key}_#{suffix}"
        File.delete(path) if File.exist?(path)
      end
    end
  end

  def trig_body_for(response_body, resource_identifier)
    statements = []
    append_local_triples(statements, response_body)
    append_hash_statements(statements, response_body, resource_identifier) if statements.empty?

    <<~TRIG
      @prefix schema: <http://schema.org/> .

      {
      #{statements.map { |statement| "  #{statement}" }.join("\n")}
      }
    TRIG
  end

  def append_local_triples(statements, obj)
    case obj
    when Hash
      triples = obj['local:triples'] || obj[:'local:triples']
      triples.each { |triple| append_triple_node(statements, triple) } if triples.is_a?(Array)
      obj.each_value { |value| append_local_triples(statements, value) }
    when Array
      obj.each { |item| append_local_triples(statements, item) }
    end
  end

  def append_triple_node(statements, triple)
    return unless triple.is_a?(Hash)

    subject = trig_subject(triple['@id'] || triple[:'@id'])
    Array(triple['@type'] || triple[:'@type']).each do |type|
      statements << "#{subject} a #{trig_resource(type)} ."
    end

    triple.each do |key, value|
      next if key.to_s.start_with?('@')

      Array(value).each do |item|
        statements << "#{subject} #{trig_predicate(key)} #{trig_object(item)} ."
      end
    end
  end

  def append_hash_statements(statements, obj, resource_identifier, path = [])
    case obj
    when Hash
      obj.each do |key, value|
        current_path = path + [key.to_s]
        if value.is_a?(Hash) || value.is_a?(Array)
          append_hash_statements(statements, value, resource_identifier, current_path)
        else
          append_schema_statement(statements, resource_identifier, current_path.last, value)
        end
      end
    when Array
      obj.each { |item| append_hash_statements(statements, item, resource_identifier, path) }
    else
      append_schema_statement(statements, resource_identifier, path.last, obj) if path.any?
    end
  end

  def append_schema_statement(statements, resource_identifier, key, value)
    return if key.nil? || key.start_with?('@') || value.nil?
    return if key.start_with?('indexing__', 'display__', 'f_')

    statements << "#{trig_subject(resource_identifier)} #{trig_predicate(key)} #{trig_object(value)} ."
  end

  def trig_subject(value)
    value.to_s.start_with?('_:') ? value.to_s : trig_resource(value)
  end

  def trig_predicate(value)
    key = value.to_s.sub(%r{\Ahttps?://schema\.org/}, '')
    key.match?(%r{\Ahttps?://}) ? trig_resource(key) : "schema:#{key.gsub(/[^A-Za-z0-9_]/, '_')}"
  end

  def trig_object(value)
    case value
    when Hash
      return trig_resource(value['@id'] || value[:'@id']) if value['@id'] || value[:'@id']
      return trig_literal(value['@value'] || value[:'@value']) if value.key?('@value') || value.key?(:'@value')

      trig_literal(value.to_json)
    else
      trig_literal(value)
    end
  end

  def trig_resource(value)
    "<#{value}>"
  end

  def trig_literal(value)
    value.to_s.dump
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
  def datacite_headers
    {
      'Accept'=>'application/vnd.citationstyles.csl+json'
    }
  end

  def parsed_response_body(body)
    body = JSON.parse(body)
    body.is_a?(String) ? JSON.parse(body) : body
  end

end

module JSON
  module LD
    class API
      def self.serializer(object, *_args, **options)
        ::JSON.generate(object, options.fetch(:serializer_opts, JSON_STATE))
      end
    end
  end
end
