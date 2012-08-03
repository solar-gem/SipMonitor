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
    respond_to do |format|
      format.html do
         if params[:cleared_data] == 'true' 
	    @alarm_str = Alarm.find(params[:id]).cleared_data.to_s
	    else
	      @alarm_str = Alarm.find(params[:id]).data.to_s
	    end
	    
	    @search_number = params[:search_number]  

      end
      format.xml  { render :nothing => true}
      format.json do



    end

    end



      
  end


end
