require 'helper'

class TestActivity < Test::Unit::TestCase
  include Hourglass # for constant scope

  def new_activity(attribs = {})
    attribs = {
      :name => 'Foo@Bar',
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

  test "requires project name" do
    activity = Activity.new(:name => nil)
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
    assert_not_nil activity_1.refresh.ended_at

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
end
