ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "home"
  
  # wiki proxy
  map.wiki ':locale/wiki/*path' ,
    :controller => "wiki",
    :action => "view"  

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  
  # Install the default route as the lowest priority.
  #map.connect ':controller/:action/:id.:format'
  map.connect(':locale/:controller/:action/:id/:period')
  map.connect ':locale/:controller/:action/:id', :period=>'3m'
  map.connect ':locale/:controller/:action/:id'
  
  # redirect old website relevant links
  map.connect 'addword', :controller=>'intword', :action=>'new'
  map.connect 'int_words', :controller=>'intword', :action=>'index'
  map.connect 'sources', :controller=>'source', :action=>'index'
  map.connect 'pages', :controller=>'page', :action=>'index'
  map.connect 'plots=plottimeseries', :controller=>'home', :action=>'index'
  map.connect 'plots=plotmultiscatter', :controller=>'home', :action=>'index'
  map.connect 'hits_per_word', :controller=>'intword', :action=>'cloud'
  map.connect 'most_5_words', :controller=>'intword', :action=>'cloud'
  map.connect 'own_query', :controller=>'home', :action=>'index'
end
