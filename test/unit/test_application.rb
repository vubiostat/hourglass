require 'helper'

class TestApplication < Test::Unit::TestCase
  include Rack::Test::Methods

  def xhr(path, params = {})
    verb = params.delete(:as) || :post
    send(verb, path, params, "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest")
  end
  alias_method :ajax, :xhr

  def app
    Hourglass::Application
  end

  test "index" do
    get "/"
    assert last_response.ok?
  end

  test "new activity form" do
    get "/activities/new"
    assert last_response.ok?
  end

  test "creating activity via ajax" do
    data = { 'name' => 'Foo@Bar', 'tag_names' => 'hey, buddy' }
    count = Hourglass::Activity.count
    xhr "/activities", 'activity' => data
    assert last_response.ok?, "Last response status was #{last_response.status}"
    assert_equal count + 1, Hourglass::Activity.count
  end
end
