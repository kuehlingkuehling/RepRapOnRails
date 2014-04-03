RepRapOnRails::Application.routes.draw do
  resources :printjobs

  root :to => "backendapp#index"

  match "upload", :to => "backendapp#upload", via: :post
  match "firmware", :to => "backendapp#firmware", via: :post  
  match "logfile", :to => "backendapp#logfile", via: :get
  match "touchapp", :to => "touchapp#index", :constraints => {:ip => /127.0.0.1/}, via: :get

end
