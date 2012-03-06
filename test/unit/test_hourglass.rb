require 'helper'

class TestHourglass < Test::Unit::TestCase
  test "db_path" do
    env = Hourglass.environment
    expected = File.join(Hourglass.data_path, 'db', env.to_s)
    assert_equal expected, Hourglass.db_path
  end
end
