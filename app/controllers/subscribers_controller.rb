# coding: utf-8

class SubscribersController < ApplicationController

  # Предварительная проверка наличия авторизации пользователя
  before_filter :authenticate_user!

  def index
    @subscribers = Subscriber.all
  end

  def new
    @subscriber = Subscriber.new
    @subscriber.errors.add(:new_sum, params[:message_sub]) if params[:message_sub]
  end

  def create
    @subscriber = Subscriber.new(params[:subscriber])
    # Проверяем валидность Equipment ID только после его нахождения (запроса на станции)
    @subscriber.request_EID_from_station if params[:subscriber][:eid] == '' && @subscriber.valid?

    if @subscriber.eid && @subscriber.eid != ''
      begin
        if @subscriber.save
          redirect_to :action => :index
        else
          render :new
        end
      rescue ActiveRecord::RecordNotUnique
        @subscriber.errors.add(:db, "Данный номер уже прописан!")
        render :new
      end
    else
      render :new
    end
  end

  def edit
    @subscriber = Subscriber.find(params[:id])
  end

  def update
    @subscriber = Subscriber.find(params[:id])
    if @subscriber.update_attributes(params[:subscriber])
      redirect_to :action => :index
    else
      render 'edit'
    end
  end
  def destroy
    @subscriber = Subscriber.find(params[:id])
    @subscriber.destroy

    redirect_to :action => :index

  end

  # Поиск аварий по номеру абонета
  def search
    if params[:number] == ''
      redirect_to alarms_url
    else
      @subscriber = Subscriber.where(full_number: params[:number]).last
      if @subscriber
puts '@' * 50
    p @subscriber

        @subscriber_id = @subscriber.id
        @subscriber_str = "(#{@subscriber.area})   #{@subscriber.number}"
        @alarms = Alarm.where(subscriber_id: @subscriber_id, status: true).order("created_at DESC")
        @alarms_history = Alarm.where(subscriber_id: @subscriber_id, status: false).limit(10).order("created_at DESC")
      else
        message_sub = "Абонент #{params[:number]} не прописан в БД. Вы можете его сейчас прописать."
        redirect_to action: :new, message_sub: message_sub unless subscriber
      end
    end
  end

end



