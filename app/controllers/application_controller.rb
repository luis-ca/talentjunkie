class ApplicationController < ActionController::Base
  
  include ApplicationHelper
  include ExceptionNotifiable
  
  helper :all
  helper_method :render_to_string, :guide_is_queued_in_session?, :guide_is_queued_in_db?, :unqueue_guide_from_session, :unqueue_guide_from_db
  helper_method :current_user
  
  #protect_from_forgery
  filter_parameter_logging :password

  around_filter :catch_exceptions
  before_filter :init, :check_authentication
  
  def init
    # FIXME: move this to environment...
    @fb_config = YAML::load(File.open("#{RAILS_ROOT}/config/facebooker.yml"))
    @fb_api_key = @fb_config[RAILS_ENV]["api_key"]
    @fb_secret_key = @fb_config[RAILS_ENV]["secret_key"]
    
    current_user.update_attribute(:last_seen, Time.now.utc) if current_user
  end
  
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

  def _collect_errors_for(*args)
    errors = {}
    args.each do |model|
      errors[model.class.name.underscore.to_sym] = model.errors if model and model.errors
    end
    errors
  end

  def collect_errors_for(*args)
    errors = {}
    args.each do |model|
      if model and model.respond_to?(:error_namespace)
        namespace = model.error_namespace.to_sym
      else
        namespace = model.class.name.underscore.to_sym
      end
      errors[namespace] = model.errors if model and model.errors
    end
    errors
  end
  
  def queue_guide_by_name(name)
    queue_guide(Guide.find_by_name(name.to_s))
  end
  
  def queue_guide(guide)
    begin
      guides = []
      guides = cookies[:guides].split('*') if cookies[:guides]
      
      if guide and !guides.include?(guide.name.to_s)
        guides.push(guide.name)
        cookies[:guides] = guides.join('*')
      end
    rescue
      raise
    end
  end
  
  def unqueue_guide_from_session(guide)
    begin
      guides = []
      guides = cookies[:guides].split('*') if cookies[:guides]
      guides.delete(guide.name)
      cookies[:guides] = guides.join('*')
    rescue
      raise
    end
  end

  def unqueue_guide_from_db(guide)
    ActiveRecord::Base.connection.execute("DELETE FROM guides_users WHERE guide_id = #{guide.id} AND user_id = #{current_user.id}")
  end

  def guide_is_queued_in_session?(guide)
    cookies[:guides].split('*').include?(guide.name.to_s) if cookies[:guides]
  end
  
  def guide_is_queued_in_db?(guide)
    ActiveRecord::Base.connection.select_value("SELECT count(*) FROM guides_users WHERE guide_id = #{guide.id} AND user_id = #{current_user.id}").to_i == 1
  end
  
  private

  def current_user
    @current_user ||= User.find(session[:user]) if session[:user]
  end

end
