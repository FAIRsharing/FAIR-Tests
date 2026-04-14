require_relative 'test_helper'

class ExampleTest < Minitest::Test
  include TestHelper

  def test_one_can_be_run
    post '/test/test_one'

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal body, {}
  end

  def test_can_read_ora_fixtures
    json_data = File.read('test/fixtures/example_fixture.json')
    parsed_data = JSON.parse(json_data)

    assert_equal 'Ensuring', parsed_data['response']['document']['abstract'].split(' ').first
  end

end