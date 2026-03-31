require_relative 'test_helper'

class ExampleTest < Minitest::Test

  def test_one_can_be_run
    get '/test/test_one'

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal "hi from the exciting module 'test one'", body['message']
  end

  def test_can_read_ora_fixtures
    json_data = File.read('test/fixtures/example_fixture.json')
    parsed_data = JSON.parse(json_data)

    assert_equal 'Ensuring', parsed_data['response']['document']['abstract'].split(' ').first
  end

end