# coding: utf-8

class SubscribersController < ApplicationController


  


  def index
    @subscribers = Subscriber.all

  end  

  def new
    redirect_to("/sessions/new") unless current_user
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.new(params[:subscriber])
    # Проверяем валидность Equipment ID только после его нахождения (запроса на станции)
    @subscriber.request_EID_from_station

    if @subscriber.save
      redirect_to :action => :index
    else
      render "new"
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
end


