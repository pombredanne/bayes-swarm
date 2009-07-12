# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  before_filter :load_configs, :set_locale
  
  def default_url_options(options={})
    { :locale => I18n.locale }
  end
  
  private
  
  def load_configs
    require 'config/environments/quasar_' + RAILS_ENV
  end  
  
  def set_locale
    if params[:locale]
      I18n.locale = params[:locale]    
    else
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
      if lang = request.env["HTTP_ACCEPT_LANGUAGE"]
        lang = lang.split(",").map { |l|
          l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
          l.split(';q=')
        }.first
        I18n.locale = lang.first.split("-").first
      end
    end    
  end 
  
end
