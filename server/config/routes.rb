Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'wolves#index'

  post '/agents/check_in/', to: "agents#check_in"

  post '/agents/store_agent', to: "agents#store_agent"
  get  '/agents/get_agent', to: "agents#get_agent"

  get  '/agents/get_task', to: "agents#get_task"

  resources :agents do
    get '/get_ticket', to: "agents#get_ticket"
    get '/make_available', to: "agents#make_available"
    get '/unload_agent', to: "agents#unload_agent"
  end

  # wolf key
  get  '/wolf/get_key', to: "wolf#get_key"

  # create aws instance
  post '/wolf/aws', to: "wolf#aws"

  post '/wolf/task', to: "wolf#task"

  resources :wolves do
  end

  resources :tasks do
    post '/close_ticket', to: "tasks#close_ticket"
  end

  resources :tickets do
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
