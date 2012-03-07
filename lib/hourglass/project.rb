module Hourglass
  class Project < Sequel::Model
    one_to_many :activities
  end
end
