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
end
