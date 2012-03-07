module Hourglass
  class Activity < Sequel::Model
    many_to_one :project
  end
end
