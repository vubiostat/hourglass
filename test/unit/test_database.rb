require 'helper'

class TestDatabase < Test::Unit::TestCase
  def setup
    super
    @database = Hourglass::Database
  end

  test "connection" do
    assert_kind_of Sequel::JDBC::Database, @database

    expected = "jdbc:h2:#{Hourglass.db_path};IGNORECASE=TRUE"
    assert_equal expected, @database.uri
  end

  test "migrate" do
    dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "db", "migrate"))
    Sequel::Migrator.expects(:run).with(@database, dir)
    @database.migrate!
  end
end
