class AlarmsController < ApplicationController
  def index
    if current_user
      @alarms = Alarm.limit(10).order("created_at DESC")
    else
      redirect_to("/sessions/new")
    end
  end
  def statistics

  end
end
