class AlarmsController < ApplicationController
  def index
    if current_user
      @alarms = Alarm.where(status: true).order("created_at DESC")

      $QQ ||= @alarms.length
      puts '/' * 50
      (@alarms.length - $QQ) > 0 ? @ring = true : @ring = false
      $QQ = @alarms.length
      puts @ring

      respond_to do |format|
        format.html 
        format.js
      end
    else
      redirect_to("/sessions/new")
    end
  end
  def statistics

  end
end
