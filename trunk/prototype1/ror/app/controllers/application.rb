# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_website_session_id'
  
  before_filter :set_locale

  def set_locale
    if !params[:locale].nil? && LOCALES.keys.include?(params[:locale])
      Locale.set LOCALES[params[:locale]]
    else
      redirect_to params.merge( 'locale' => Locale.base_language.code )
    end
  end
    
end
