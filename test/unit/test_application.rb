require 'helper'

class TestApplication < Test::Unit::TestCase
  include Rack::Test::Methods
  include Hourglass

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
    assert last_response.ok?, last_response.body
  end

  test "new activity form" do
    get "/activities/new"
    assert last_response.ok?, last_response.body
  end

  test "creating activity via ajax" do
    data = { 'name' => 'Foo@Bar', 'tag_names' => 'hey, buddy', 'running' => '1' }
    count = Activity.count
    xhr "/activities", 'activity' => data
    assert last_response.ok?, last_response.body
    assert_equal count + 1, Activity.count

    result = JSON.parse(last_response.body)
    assert_equal "Foo", result['activity']['name']
    assert_equal "Bar", result['activity']['project']['name']
    assert result.has_key?('today')
    assert result.has_key?('week')
    assert result.has_key?('current')
  end

  test "creating activity via ajax stops other activities" do
    activity_1 = Activity.create(:name => 'Junk@Baz', :started_at => Time.now - 12345, :running => true)

    data = { 'name' => 'Foo@Bar', 'tag_names' => 'hey, buddy', 'running' => '1' }
    count = Activity.count
    xhr "/activities", 'activity' => data
    assert last_response.ok?, last_response.body
    assert_equal count + 1, Activity.count

    activity_1.reload
    assert_not_nil activity_1.ended_at
  end

  test "fetching activities by day" do
    today = Time.now
    yesterday = today - 24 * 60 * 60
    activity_1 = Activity.create(:name => 'Foo@Bar', :started_at => today, :running => true)
    activity_2 = Activity.create(:name => 'Baz@Qux', :started_at => yesterday - 10 * 60, :ended_at => yesterday)
    get "/activities", { 'd' => Date.today.strftime("%Y%m%d") }
    assert last_response.ok?, last_response.body
    assert_equal Activity.filter(:id => activity_1.id).to_json(:include => [:tags, :project]), last_response.body
  end

  test "stop current activities" do
    activity = Activity.create(:name => 'Foo@Bar', :started_at => Time.now - 12345, :running => true)
    xhr "/activities/current/stop", :as => :get
    assert last_response.ok?, last_response.body
    activity.reload
    assert_not_nil activity.ended_at
  end
end
