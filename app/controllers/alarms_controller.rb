class AlarmsController < ApplicationController

  # Предварительная проверка наличия авторизации пользователя
  before_filter :authenticate_user!

  def index
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
  end
  def statistics
    @sub_all = Subscriber.all.count
    @sub_all_control = Subscriber.where(:control => true).count
    @sub_alarm = Alarm.where(status: true).count
  end

  def show
    @alarm = Alarm.find(params[:id])
    @search_number = params[:search_number]
  end


end
