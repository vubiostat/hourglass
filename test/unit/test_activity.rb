require 'helper'

class TestActivity < Test::Unit::TestCase
  include Hourglass # for constant scope

  test "creates non-existent project" do
    activity = Activity.create(:name => 'foo@bar')
    assert_not_nil activity.project
    assert_equal "bar", activity.project.name
  end

  test "uses existing project" do
    project = Project.create(:name => 'bar')
    activity = Activity.create(:name => 'foo@bar')
    assert_equal project, activity.project
  end

  test "finds or creates tags" do
    tag_1 = Tag.create(:name => 'foo')
    tag_2 = Tag.create(:name => 'bar')
    count = Tag.count
    activity = Activity.create(:name => 'foo@bar', :tag_names => 'foo, bar, baz')
    assert_equal 3, activity.tags.length
    assert_equal count + 1, Tag.count
    assert_not_nil Tag.filter(:name => 'baz').first
  end

  test "removes old tags on update" do
    activity = Activity.create(:name => 'foo@bar', :tag_names => 'foo, bar, baz')
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
    activity = Activity.create(:name => 'foo', :started_at => Time.now - 12345)
    assert (activity.duration - 12345000).abs < 100
  end

  test "duration for finished activity" do
    now = Time.now
    activity = Activity.create(:name => 'foo', :started_at => now - 45678, :ended_at => now)
    assert (activity.duration - 45678000).abs < 100
  end

  test "running? is true when ended_at is not nil" do
    activity = Activity.create(:name => 'foo', :started_at => Time.now - 12345)
    assert activity.running?
    activity.update(:ended_at => Time.now)
    assert !activity.running?
  end
end
