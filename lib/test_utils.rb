require 'httparty'

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
    # TODO: Content negotation needed (Mark's tool?)
    headers = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }

    response = HTTParty.get(url, headers: headers)
    body = JSON.parse(response.body)
    #status = response.code,
    #message = response.message

    body
  end

end