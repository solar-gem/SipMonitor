class ApplicationController < ActionController::Base
  protect_from_forgery

# Создаем метод current_user, который возвращает текущего пользователя.
  private

  def current_user
   # @current_user ||= User.find(session[:user_id]) if session[:user_id]
    @current_user ||= User.where(id: session[:user_id]).first if session[:user_id]
  end
  
  # Проверка авторизации пользователя
  def authenticate_user!
    redirect_to("/sessions/new") unless current_user
  end

  helper_method :current_user
  # helper_method :authenticate_user!
end
