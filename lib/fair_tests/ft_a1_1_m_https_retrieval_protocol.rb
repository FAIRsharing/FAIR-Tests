module FtA11MHttpsRetrievalProtocol
  require_relative '../fair_test_utils'
  include FairTestUtils

  def ft_a1_1_m_https_retrieval_protocol(url_record)
    meta = {
      testid: 'FT_A1.1_M_HTTPSRetrievalProtocol.ttl',
      testname: 'FAIR Metric – A1.1 – Metadata - HTTP(S) retrieval protocol',
      description: "This metric evaluates whether the protocol used to retrieve metadata referenced by the provided identifier is either HTTP or HTTPS and therefore openly specified, free to implement, and universally implementable.",
      keywords: ['FAIR', 'A1.1', 'https'],
      creator: 'https://orcid.org/0000-0002-6468-9260',
      indicators: [],
      metric: 'https://fairsharing.org/10.25504/FAIRsharing.79aee0',
      license: 'https://creativecommons.org/licenses/by/4.0/',
      testversion: '1.0.0',
      protocol: 'https',
      host: 'ostrails.github.io',
      basePath: '/assessment-component-metadata-records/test/',
      endpoint_url: 'https://fair-tests.fairsharing.org/test/ft_a1_1_m_https_retrieval_protocol',
      endpoint_description: 'https://fair-tests.fairsharing.org/test_descriptions/ft_a1_1_m_https_retrieval_protocol/api',
    }

    response = FtrRuby::Output.new(
      testedGUID: url_record,
      meta: meta,
    )

    url_to_test = if url_record.start_with?('https://')
                    url_record
                  elsif url_record.start_with?('http://')
                    url_record.gsub('http://', 'https://')
                  else
                    "https://#{url_record}"
                  end

    begin
      data = HTTParty.head(url_to_test, timeout: 10, follow_redirects: true)
      if data.success?
        response.score = 'pass'
        response.comments << 'The record is accessible via HTTPS.'
      else
        response.score = 'fail'
        response.comments << 'The record is not accessible via HTTPS.'
      end
    rescue OpenSSL::SSL::SSLError => e
      response.score = 'fail'
      response.comments << "The record is not accessible via HTTPS. The error message on attempted retrieval is: #{e.message}."
    rescue Socket::ResolutionError
      response.score = 'fail'
      response.comments << 'The record could not be found.'
    end

    response.createEvaluationResponse
  end
end
