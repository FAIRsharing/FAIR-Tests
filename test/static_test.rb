require_relative './test_helper'

class StaticTest < Minitest::Test
  include TestHelper
  def test_root_returns_welcome_message
    get '/'

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal 'Welcome to the FAIR Tests API', body['message']
  end

  def test_list_tests_returns_list_of_tests
    get '/list_tests'

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal 'List of available tests. Prepend /test/ to run a test and access with POST.', body['message']
    assert_equal body['tests'].count, Dir.entries('./lib/fair_tests').reject { |f| f.start_with?('.') }.count
  end

  def test_404
    get '/not_found'
    assert last_response.not_found?
  end

  def test_not_found
    post '/test/no_such_test',
         { params: { resource_identifier: 'https://example.org/x' }.to_json }.to_json,
         {
           'CONTENT_TYPE' => 'application/json',
           'HTTP_ACCEPT' => 'application/json'
         }
    res = JSON.parse(last_response.body)
    assert_equal 'Test no_such_test not found.', res['message']
  end
end