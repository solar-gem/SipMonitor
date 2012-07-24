class AlarmsController < ApplicationController
  def index
    @alarms = Alarm.all
  end
  def statistics

  end
end
