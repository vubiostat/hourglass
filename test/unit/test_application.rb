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
    data = { 'name_with_project' => 'Foo@Bar', 'tag_names' => 'hey, buddy', 'running' => '1' }
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
    activity_1 = Activity.create(:name_with_project => 'Junk@Baz', :started_at => Time.now - 12345, :running => true)

    data = { 'name' => 'Foo@Bar', 'tag_names' => 'hey, buddy', 'running' => '1' }
    count = Activity.count
    xhr "/activities", 'activity' => data
    assert last_response.ok?, last_response.body
    assert_equal count + 1, Activity.count

    activity_1.reload
    assert_not_nil activity_1.ended_at
  end

  test "edit activity form" do
    activity = Activity.create(:name_with_project => 'Foo@Bar', :tag_names => 'hey, buddy', :started_at => Time.now - 12345, :running => true)
    get "/activities/#{activity.id}/edit"
    assert last_response.ok?, last_response.body
  end

  test "updating activity" do
    started_at = Time.now - 12345
    activity = Activity.create(:name_with_project => 'Foo@Bar', :tag_names => 'hey, buddy', :started_at => started_at, :running => true)

    ended_at = Time.now
    data = {
      'name_with_project' => 'Foo@Baz',
      'tag_names' => 'hey, buddy',
      'started_at_mdy' => activity.started_at_mdy,
      'started_at_hm' => activity.started_at_hm,
      'ended_at_mdy' => ended_at.strftime("%m/%d/%Y"),
      'ended_at_hm' => ended_at.strftime("%H:%M")
    }
    xhr "/activities/#{activity.id}", { 'activity' => data }
    assert last_response.ok?

    activity.reload
    assert !activity.running?
  end

  test "fetching activities" do
    day = 24 * 60 * 60
    today = Time.now
    yesterday = today - day

    activity_1 = Activity.create(:name_with_project => 'Foo@Bar', :started_at => today, :running => true)
    activity_2 = Activity.create(:name_with_project => 'Baz@Blargh', :started_at => yesterday - 60, :ended_at => yesterday)
    activity_3 = Activity.create(:name_with_project => 'Foo@Bar', :started_at => yesterday - 120, :ended_at => yesterday - 60)
    activity_4 = Activity.create(:name_with_project => 'Blah@Junk', :started_at => yesterday - 180, :ended_at => yesterday - 120)
    get "/activities"
    assert last_response.ok?, "Response wasn't okay"

    expected = [
      {'activity_name' => 'Baz', 'project_name' => 'Blargh'},
      {'activity_name' => 'Blah', 'project_name' => 'Junk'},
      {'activity_name' => 'Foo', 'project_name' => 'Bar'}
    ]
    result = JSON.parse(last_response.body)
    assert_equal expected, result.collect { |x| Hash[x.select { |k, v| k == 'activity_name' || k == 'project_name' }] }
  end

  test "fetching tags" do
    tag_1 = Tag.create(:name => 'foo')
    tag_2 = Tag.create(:name => 'bar')
    get "/tags"
    assert last_response.ok?, "Response wasn't okay"
    assert_equal %w{bar foo}.to_json, last_response.body
  end

  test "stop current activities" do
    activity = Activity.create(:name_with_project => 'Foo@Bar', :started_at => Time.now - 12345, :running => true)
    xhr "/activities/current/stop", :as => :get
    assert last_response.ok?, last_response.body
    activity.reload
    assert_not_nil activity.ended_at
  end

  test "delete activity" do
    activity = Activity.create(:name_with_project => 'Foo@Bar', :tag_names => "foo, bar", :started_at => Time.now - 12345, :running => true)
    xhr "/activities/#{activity.id}/delete", :as => :get
    assert last_response.ok?, last_response.body
    assert_nil Activity[activity.id]
  end
end
