class ApplicationController < ActionController::Base
  protect_from_forgery

# Создаем метод current_user, который возвращает текущего пользователя.
  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user
end
