require_relative 'test_helper'

class StaticTest < Minitest::Test
  def test_root_returns_welcome_message
    get '/'

    assert last_response.ok?

    body = JSON.parse(last_response.body)
    assert_equal 'Welcome to the FAIR Tests API', body['message']
  end
end