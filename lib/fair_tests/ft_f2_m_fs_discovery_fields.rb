# frozen_string_literal: true

module FtF2MFsDiscoveryFields
  require 'ftr_ruby'
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_f2_m_fs_discovery_fields(url_record)
    record = obtain_record_from_text(url_record)

    meta = {
      testid: 'Ft_F2_M_FsDiscoveryFields.ttl',
      testname: 'FAIR Test - F2 - FAIRsharing metadata fields for resource discovery',
      description: 'This metric assesses whether the FAIRsharing record contains values for the following fields: resource name, description, country, at least one subject, and at least one object type.',
      keywords: ['ARK', 'FAIR', 'F2'],
      creator: '0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/8368/',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_f2_m_fs_discovery_fields',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_f2_m_fs_discovery_fields/api',
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
      end

      if pass
        response.score = 'pass'
        response.comments << 'This record contains the required FAIRsharing discovery fields.'
      end
    end

    response.createEvaluationResponse
  end
end
