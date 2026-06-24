# frozen_string_literal: true

module FtF2MFsLsDiscoveryFields
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  LIFE_SCIENCE_SUBJECT_ID = 1337

  def ft_f2_m_fs_ls_discovery_fields(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'Ft_F2_M_FsLsDiscoveryFields.ttl',
      testname: 'FAIR Test - F2 - FAIRsharing metadata fields for life sciences resource discovery',
      description: 'This test assesses whether the FAIRsharing record contains values for the following fields: resource name, description, country, at least one subject, and at least one object type. At least one subject assigned to the record must belong to the Life Sciences hierarchy of the FAIRsharing Subject Resource Application Ontology (SRAO).',
      keywords: ['ARK', 'FAIR', 'F2', 'life sciences'],
      creator: '0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8369/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f1_m_guidark',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f1_m_guidark/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    if record && !record.empty?
      pass = true

      if record['name'].nil? || record['name'].empty?
        pass = false
        response.score = 'fail'
        response.comments << 'This record does not contain a name.'
      end

      if record['description'].nil? || record['description'].empty?
        pass = false
        response.score = 'fail'
        response.comments << 'This record does not contain a description.'
      end

      if record['countries'].nil? || record['countries'].empty?
        pass = false
        response.score = 'fail'
        response.comments << 'This record does not contain a country.'
      end

      if record['objectTypes'].nil? || record['objectTypes'].empty?
        pass = false
        response.score = 'fail'
        response.comments << 'This record does not contain any object types.'
      end

      if record['subjects'].nil? || record['subjects'].empty?
        pass = false
        response.score = 'fail'
        response.comments << 'This record does not contain any subjects.'
      else
        life_science_subjects = get_life_science_subjects
        record_subjects = record['subjects'].map do |subject|
          (subject['name'] || subject['label']).to_s.downcase
        end
        unless (life_science_subjects & record_subjects).any?
          pass = false
          response.score = 'fail'
          response.comments << 'This record does not contain any subjects from the Life Sciences hierarchy.'
        end
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains the required life science fields.'
      end

    end

    response.createEvaluationResponse
  end

  private

  def get_life_science_subjects
    # First, get data from the FAIRsharing GraphQL API.
    # The query is: {browseSubjects{ data }}
    # Then, search through the object to find the subject with a given ID.
    # There is an example file provided to determine the structure: subjects.json
    # For the subject found, recursively traverse all children and get their names.
    # Downcase all names and put them in an array.
    subjects = fetch_browse_subjects
    life_science_subject = find_subject_by_id(subjects, LIFE_SCIENCE_SUBJECT_ID)

    return [] if life_science_subject.nil?

    collect_subject_names(life_science_subject).uniq
  end

  def fetch_browse_subjects
    subjects = fetch_remote_browse_subjects
    return subjects unless subjects.empty?

    fetch_local_browse_subjects
  end

  def fetch_remote_browse_subjects
    response = HTTParty.post(
      ENV['FAIRSHARING_API_URL'],
      body: { query: '{browseSubjects{ data }}' }.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'X-GraphQL-Key' => ENV['FAIRSHARING_API_KEY']
      }
    )

    return [] unless response.code == 200

    JSON.parse(response.body).dig('data', 'browseSubjects', 'data') || []
  rescue StandardError
    []
  end

  def fetch_local_browse_subjects
    path = File.expand_path('../../subjects.json', __dir__)

    JSON.parse(File.read(path)).dig('data', 'browseSubjects', 'data') || []
  rescue StandardError
    []
  end

  def find_subject_by_id(subjects, subject_id)
    Array(subjects).each do |subject|
      next unless subject.is_a?(Hash)

      return subject if subject['id'].to_i == subject_id

      matching_child = find_subject_by_id(subject['children'], subject_id)
      return matching_child unless matching_child.nil?
    end

    nil
  end

  def collect_subject_names(subject)
    return [] unless subject.is_a?(Hash)

    names = []
    names << subject['name'].downcase if subject['name'].is_a?(String)

    Array(subject['children']).each do |child|
      names.concat(collect_subject_names(child))
    end

    names
  end

end
