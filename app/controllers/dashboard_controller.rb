class DashboardController < ApplicationController
  def index
    redirect_to("/sessions/new") unless current_user
    #@number = vendor("ims_lst_sub.rb") # `ruby ./vendor/ims_lst_sub.rb`
  end
end
