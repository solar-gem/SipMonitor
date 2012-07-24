class Alarm < ActiveRecord::Base
  belongs_to :subscriber
  attr_accessible :alarm_raised_time, :cleared_time, :data
end
