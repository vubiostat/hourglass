require 'helper'

class TestActivity < Test::Unit::TestCase
  include Hourglass # for constant scope

  def new_activity(attribs = {})
    attribs = {
      :name_with_project => 'Foo@Bar',
      :started_at => Time.now,
      :running => true
    }.merge(attribs)
    Activity.new(attribs)
  end

  test "creates non-existent project" do
    activity = new_activity.save
    assert_not_nil activity.project
    assert_equal "Bar", activity.project.name
  end

  test "uses existing project" do
    project = Project.create(:name => 'Bar')
    activity = new_activity.save
    assert_equal project, activity.project
  end

  test "finds or creates tags" do
    tag_1 = Tag.create(:name => 'foo')
    tag_2 = Tag.create(:name => 'bar')
    count = Tag.count
    activity = new_activity(:tag_names => 'foo, bar, baz').save
    assert_equal 3, activity.tags.length
    assert_equal count + 1, Tag.count
    assert_not_nil Tag.filter(:name => 'baz').first
  end

  test "removes old tags on update" do
    activity = new_activity(:tag_names => 'foo, bar, baz').save
    assert_equal 3, activity.tags.length
    activity.tag_names = "foo, quux"
    activity.save
    assert_equal 2, activity.tags.length
    assert_equal 2, Database[:activities_tags].filter(:activity_id => activity.id).count
  end

  test "requires name" do
    activity = Activity.new(:name_with_project => nil)
    assert !activity.valid?, "Activity was valid when it shouldn't have been"
  end

  test "duration for current activity" do
    activity = new_activity(:started_at => Time.now - 12345).save
    assert (activity.duration - 12345).abs < 1
  end

  test "duration for finished activity" do
    now = Time.now
    activity = new_activity(:started_at => now - 45678, :ended_at => now, :running => false).save
    assert (activity.duration - 45678).abs < 1
  end

  test "duration in words" do
    ended = Time.now
    started = ended - (60 * 150)
    activity = new_activity(:started_at => started, :ended_at => ended, :running => false)
    assert_equal "2h 30min", activity.duration_in_words

    activity.started_at = ended - (60 * 60 * 25)
    assert_equal "1d 1h", activity.duration_in_words
  end

  test "running? is true if activity is not new and ended_at is not nil" do
    activity = new_activity.save
    assert activity.running?
    activity.update(:ended_at => Time.now)
    assert !activity.running?
  end

  test "running? is true if activity is new and the running attribute is set" do
    activity = new_activity(:running => true)
    assert activity.running?
    activity.running = false
    assert !activity.running?
  end

  test "stop_current_activities" do
    activity_1 = new_activity(:started_at => Time.now - 12345).save
    Activity.stop_current_activities
    activity_1.refresh
    assert_not_nil activity_1.ended_at

    activity_2 = new_activity(:started_at => Time.now - 30).save
    Activity.stop_current_activities
    assert_equal 0, Activity.filter(:id => activity_2.id).count
  end

  test "stop_current_activities deletes tag relationships" do
    activity = new_activity(:tag_names => "hey,buddy", :started_at => Time.now - 30).save
    Activity.stop_current_activities
    assert_equal 0, Activity.filter(:id => activity.id).count
  end

  test "started_at_mdy" do
    now = Time.now; started = now - 45678; ended = now
    activity = new_activity(:started_at => started, :ended_at => ended, :running => false).save
    assert_equal started.strftime("%m/%d/%Y"), activity.started_at_mdy
  end

  test "started_at_hm" do
    now = Time.now; started = now - 45678; ended = now
    activity = new_activity(:started_at => started, :ended_at => ended, :running => false).save
    assert_equal started.strftime("%H:%M"), activity.started_at_hm
  end

  test "ended_at_mdy" do
    now = Time.now; started = now - 45678; ended = now
    activity = new_activity(:started_at => started, :ended_at => ended, :running => false).save
    assert_equal ended.strftime("%m/%d/%Y"), activity.ended_at_mdy
  end

  test "ended_at_hm" do
    now = Time.now; started = now - 45678; ended = now
    activity = new_activity(:started_at => started, :ended_at => ended, :running => false).save
    assert_equal ended.strftime("%H:%M"), activity.ended_at_hm
  end

  test "tag_names getter" do
    now = Time.now; started = now - 45678; ended = now
    activity_1 = new_activity(:started_at => started, :ended_at => ended, :running => false).save
    assert_equal "", activity_1.tag_names
    activity_1.add_tag(Tag.new(:name => 'foo'))
    assert_equal "foo", activity_1.tag_names
    activity_1.add_tag(Tag.new(:name => 'bar'))
    assert_equal "foo, bar", activity_1.tag_names

    activity_2 = Activity.new
    assert "", activity_2.tag_names
  end

  test "requires started_at" do
    activity = new_activity(:started_at => nil)
    assert !activity.valid?
  end

  test "requires ended_at if not running" do
    activity = new_activity(:running => false)
    assert !activity.valid?
  end

  test "create running activity from date pieces" do
    attribs = {
      'name' => 'Foo@Bar',
      'tag_names' => 'junk, blah',
      'started_at_mdy' => '3/14/2012',
      'started_at_hm' => '10:15',
      'running' => 'true'
    }
    activity = Activity.new(attribs)
    assert activity.valid?
    activity.save

    assert_equal Time.local(2012, 3, 14, 10, 15), activity.started_at
    assert activity.running?
  end

  test "create finished activity from date pieces" do
    attribs = {
      'name' => 'Foo@Bar',
      'tag_names' => 'junk, blah',
      'started_at_mdy' => '3/14/2012',
      'started_at_hm' => '10:15',
      'ended_at_mdy' => '3/14/2012',
      'ended_at_hm' => '13:15'
    }
    activity = Activity.new(attribs)
    assert activity.valid?
    activity.save

    assert_equal Time.local(2012, 3, 14, 10, 15), activity.started_at
    assert_equal Time.local(2012, 3, 14, 13, 15), activity.ended_at
    assert !activity.running?
  end

  test "name_with_project" do
    activity = new_activity(:name_with_project => 'Foo@Bar').save
    assert_equal "Foo@Bar", activity.name_with_project
  end

  test "uniq" do
    now = Time.now
    activity_1 = new_activity(:name_with_project => 'Foo@Bar', :started_at => now -  60, :ended_at => now      , :running => false).save
    activity_2 = new_activity(:name_with_project => 'Foo@Bar', :started_at => now - 120, :ended_at => now -  60, :running => false).save
    activity_3 = new_activity(:name_with_project => 'Foo@Baz', :started_at => now - 180, :ended_at => now - 120, :running => false).save
    assert_equal [activity_1, activity_3], Activity.uniq.all
  end

  test "uniq with pre-joined dataset" do
    now = Time.now
    activity_1 = new_activity(:name_with_project => 'Foo@Bar', :started_at => now -  60, :ended_at => now      , :running => false).save
    activity_2 = new_activity(:name_with_project => 'Foo@Bar', :started_at => now - 120, :ended_at => now -  60, :running => false).save
    activity_3 = new_activity(:name_with_project => 'Foo@Baz', :started_at => now - 180, :ended_at => now - 120, :running => false).save
    actual =
      Activity.select(:activities.*).
      filter(:projects__name.like("Baz%")).
      join(:projects, :id => :project_id).uniq.all
    assert_equal [activity_3], actual
  end

  test "update activity name" do
    ended_at = Time.now
    started_at = ended_at - 12345
    activity = new_activity({
      :name_with_project => 'Foo@Bar', :running => false,
      :started_at => started_at, :ended_at => ended_at
    }).save

    activity.set(:name_with_project => "Bar@Baz")
    assert activity.valid?
    assert activity.save
    assert_equal "Bar", activity.name
    assert_equal "Baz", activity.project.name
  end

  test "update finished activity to be running" do
    ended_at = Time.now
    started_at = ended_at - 12345
    activity = new_activity({
      :name_with_project => 'Foo@Bar', :running => false,
      :started_at => started_at, :ended_at => ended_at
    }).save

    activity.update({:running => true})
    assert_nil activity.ended_at
  end

  test "delete activity with tags" do
    activity = new_activity(:tag_names => "foo, bar").save
    activity.destroy
  end

  test "#changes when creating activity with all new unique things" do
    activity = new_activity(:tag_names => "foo, bar").save
    expected = {
      'new_activity' => 'Foo@Bar',
      'new_project' => 'Bar',
      'new_tags' => %w{foo bar}
    }
    assert_equal expected, activity.changes
  end

  test "#changes when creating activity with existing things" do
    now = Time.now
    activity_1 = new_activity({
      :tag_names => "foo, bar", :running => false,
      :started_at => now - 12345, :ended_at => now
    }).save
    activity_2 = new_activity(:tag_names => "foo, bar, baz").save

    expected = {
      'new_tags' => %w{baz}
    }
    assert_equal expected, activity_2.changes
  end

  test "#changes when updating activity" do
    activity = new_activity(:tag_names => "foo, bar").save
    activity.update(:name_with_project => 'Foo@Baz')
    expected = {
      'new_activity' => 'Foo@Baz',
      'new_project' => 'Baz',
      'delete_activity' => 'Foo@Bar'
    }
    assert_equal expected, activity.changes
  end

  test "#changes when deleting activity" do
    now = Time.now
    activity_1 = new_activity(:running => false, :started_at => now - 12345, :ended_at => now - 1234).save
    activity_2 = new_activity(:running => false, :started_at => now - 1234, :ended_at => now - 123).save

    activity_1.destroy
    assert_equal({}, activity_1.changes)

    activity_2.destroy
    assert_equal({"delete_activity" => "Foo@Bar"}, activity_2.changes)
  end

  test "start_like starts activity like existing activity" do
    now = Time.now
    activity_1 = new_activity(:running => false, :started_at => now - 12345, :ended_at => now - 1234, :tag_names => "foo, bar").save
    activity_2 = Activity.start_like(activity_1)
    assert_equal activity_1.name_with_project, activity_2.name_with_project
    assert_equal activity_1.tag_names, activity_2.tag_names
  end

  test "start_like doesn't start already running activity" do
    activity_1 = new_activity.save
    activity_2 = Activity.start_like(activity_1)
    assert !activity_2
    assert_equal 1, Activity.current.count
  end

  test "start_like doesn't start identical activity" do
    now = Time.now
    activity_1 = new_activity(:running => false, :started_at => now - 12345, :ended_at => now - 1234, :tag_names => "foo, bar").save
    activity_2 = Activity.start_like(activity_1)
    activity_3 = Activity.start_like(activity_1)
    assert !activity_3
    assert_equal 1, Activity.current.count
  end

  test "start_like stops current activities" do
    now = Time.now
    activity_1 = new_activity(:name_with_project => 'Foo@Bar', :running => false, :started_at => now - 12345, :ended_at => now - 1234, :tag_names => "foo, bar").save
    activity_2 = new_activity(:name_with_project => 'Bar@Baz').save
    activity_3 = Activity.start_like(activity_1)
    assert_equal 1, Activity.current.count
  end
end
