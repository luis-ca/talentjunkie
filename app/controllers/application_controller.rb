class ApplicationController < ActionController::Base
  
  helper :all
  # include Authentication
  #protect_from_forgery
  filter_parameter_logging :password

  helper_method :current_user
  
  around_filter :catch_exceptions
  # before_filter :check_fb_session, :check_authentication
  
  protected
  
  def check_authentication
    raise SecurityError unless current_user
  end

  def catch_exceptions
    begin
      yield
    rescue SecurityError
      redirect_to :welcome
      return false
    rescue
      raise
    end
  end

  def collect_errors_for(*args)
    errors = {}
    args.each do |model|
      errors[model.class.name.underscore.to_sym] = model.errors if model and model.errors
    end
    errors
  end

  private

  # def current_user_session
  #   @current_user_session ||= UserSession.find
  # end
  # 
  def current_user
    @current_user ||= User.find(session[:user])
  end


end
