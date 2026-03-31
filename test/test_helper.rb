ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../fair_tests'

class Minitest::Test
  include Rack::Test::Methods

  def app
    FairTests
  end
end