require 'sinatra'
require 'json'
require 'dotenv/load'

class FairTests < Sinatra::Base

  set :public_folder, 'public'

  # Modules containing the FAIR Tests:
  Dir[File.join(__dir__, 'lib', 'fair_tests', '*.rb')].sort.each do |file|
    require file
    mod_name = File.basename(file, '.rb').split('_').map(&:capitalize).join
    helpers Object.const_get(mod_name)
  end

  # Welcome message to indicate the API is up and running:
  # TODO: Add a link to documentation.
  get '/' do
    json message: 'Welcome to the FAIR Tests API'
  end

  get '/list_tests' do
    content_type :json
    json message: 'List of available tests. Prepend /test/ to run a test and access with POST.',
         tests: Dir.entries('./lib/fair_tests')
                   .reject { |f| f.start_with?('.') }
                   .map { |f| f.split('.').first }

  end

  # Get a specific test:
  post '/test/:test_name' do
    # This parses the body for additional JSON parameters.
    # Test name is in the URL, identifier to check is in the additional JSON.
    raw_body = request.body.read
    json_params = raw_body.empty? ? {} : JSON.parse(raw_body)
    all_params = params.merge(json_params)

    # If the test exists, call it, passing the resource identifier.
    if respond_to?(params[:test_name])
      json public_send(params[:test_name], all_params['resource_identifier'])
    else
      json message: "Test #{params[:test_name]} not found."
    end
  end

  # Default JSON 404.
  not_found do
    status 404
    json error: 'Not Found'
  end

  helpers do
    def json(payload)
      content_type :json
      JSON.generate(payload)
    end
  end

end
