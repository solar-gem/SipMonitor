class SubscribersController < ApplicationController
  def new
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.new(params[:subscriber])
    if @subscriber.save
      redirect_to root_url, :notice => "Signed up!"
    else
      render "new"
    end
  end
end
