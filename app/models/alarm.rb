class Alarm < ActiveRecord::Base
  belongs_to :subscriber
  attr_accessible :alarm_raised_time, :cleared_time, :data


  def statistics
     time_now = Time.now
     year = time_now.year
     month = time_now.month
     day = time_now.day
  Alarm.where(:alarm_raised_time => (Time.utc(time_now.year, time_now.month, time_now.day, t1))..Time.utc(time_now.year, time_now.month, time_now.day, t2)).count
  
  end
end
