# coding: utf-8

class SubscribersController < ApplicationController
  def index
    @subscribers = Subscriber.all

  end  

  def new
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.new(params[:subscriber])
    if @subscriber.save
      redirect_to :action => :index
    else
      render "new"
    end
  end
  def edit
    @subscriber = Subscriber.find(params[:id])
    render :new
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


