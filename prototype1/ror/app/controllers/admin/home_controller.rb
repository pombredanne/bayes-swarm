class Admin::HomeController < ApplicationController
  #layout "admin"
  layout "standard"
  before_filter :authorize  
end
