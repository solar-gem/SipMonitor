# coding: utf-8
class SessionsController < ApplicationController

  def index
    render "new"
  end

  def new
    redirect_to '/alarms' if current_user # Если пользователь ранее уже был зарегистрирован, то при переходе на станицу авторизации (корень сайта) его автоматически направляют на рабочую страницу
  end

  def create
    user = User.find_by_email(params[:email])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to '/alarms'#, :notice => "Logged in!"
    else
      flash.now.alert = "Ошибка авторизации. Не верный email или пароль."
      render "new"
    end
  end

  def destroy    
    session[:user_id] = nil
    redirect_to root_url, :notice => "Сессия завершена!"
  end
end
