class Alarm < ActiveRecord::Base
  belongs_to :subscriber
  attr_accessible :alarm_raised_time, :cleared_time, :data


  def self.statistics
     time_now = Time.now
     year = time_now.year
     month = time_now.month
     day = time_now.day
     hour = time_now.hour
     
     alarm_all_count = []
     alarm_count = []
     alarm_cleared_count = []

     (0..hour).each do |hour_tmp|
        alarm_all = Alarm.where(:alarm_raised_time => (Time.utc(year, month, day, 0))..Time.utc(year, month, day, hour_tmp + 1)).count
        cleared_all = Alarm.where(:cleared_time => (Time.utc(year, month, day, 0))..Time.utc(year, month, day, hour_tmp + 1)).count
        alarm_all_count << (alarm_all - cleared_all)

        alarm_count << Alarm.where(:alarm_raised_time => (Time.utc(year, month, day, hour_tmp))..Time.utc(year, month, day, hour_tmp + 1)).count

        alarm_cleared_count << Alarm.where(:cleared_time => (Time.utc(year, month, day, hour_tmp))..Time.utc(year, month, day, hour_tmp + 1)).count
     end


     {alarm_all_count: alarm_all_count, alarm_count: alarm_count, alarm_cleared_count: alarm_cleared_count} 

 
  end
end
