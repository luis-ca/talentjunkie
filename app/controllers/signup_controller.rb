class SignupController < PublicController
  
  skip_before_filter :redirect_if_session_exists  
  
  def create
    @user = SimpleUser.new
    @user.first_name = params[:simple_user][:first_name]
    @user.last_name = params[:simple_user][:last_name]
    @user.primary_email = params[:simple_user][:primary_email]
    @user.password = params[:simple_user][:password]
    
    @user.detail = UserDetail.create!
    begin
      @user.save!
      session[:user] = @user.id
      render :json => {:url => "/my/profile"}.to_json, :status => 201
    rescue
      render :json => collect_errors_for(@user).to_json, :status => 406
    end
  end
  
end