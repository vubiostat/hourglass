require 'helper'

class TestApplication < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Hourglass::Application
  end

  test "index" do
    get "/"
    assert last_response.ok?
  end
end
