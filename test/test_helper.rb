ENV['RACK_ENV'] = 'test'

require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/config/'
end

require 'minitest/autorun'
require 'rack/test'
require_relative '../fair_tests'

module TestHelper
  include Rack::Test::Methods

  def app
    FairTests
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end
