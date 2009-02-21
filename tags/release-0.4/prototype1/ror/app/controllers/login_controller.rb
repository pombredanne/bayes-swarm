class LoginController < ApplicationController
  #layout "admin"
  layout "standard"
  before_filter :authorize, :except => :login
  
  def login
    if request.get?
      session[:user_id] = nil
      @user = User.new
    else
      @user = User.new(params[:user])
      logged_in_user = @user.try_to_login
      if logged_in_user
         session[:user_id] = logged_in_user.id         
         jumpto = session[:jumpto] || { :controller => "/admin", :action => "index" }
         session[:jumpto] = nil
         redirect_to(jumpto)
      else
         flash[:notice] = "Invalid user/password combination"
      end
    end
  end
  
  def logout
    session[:user_id] = nil
    flash[:notice] = "Logged out"
    redirect_to(:action => "login")
  end

end
