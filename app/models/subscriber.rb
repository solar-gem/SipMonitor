class Subscriber < ActiveRecord::Base
  has_many :alarm
  attr_accessible :address, :control, :name, :number
end
