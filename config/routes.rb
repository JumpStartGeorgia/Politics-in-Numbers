Rails.application.routes.draw do
  match '/permalink', :to => 'admin#permalink', :as => :permalink, :via => :get, constraints: {format: :json}
  scope ':locale', locale: /#{I18n.available_locales.join("|")}/ do
    post '/users', to: 'users#create'

    devise_for :users,
               controllers: {
                 confirmations: 'users/confirmations',
                 omniauth: 'users/omniauth',
                 passwords: 'users/passwords',
                 registrations: 'users/registrations',
                 sessions: 'users/sessions',
                 unlocks: 'users/unlocks'
               },
               constraints: { format: :html }
    match '/admin', :to => 'admin#index', :as => :admin, :via => :get
    namespace :admin, :constraints => { format: :html } do
      get :categories, :to => "/admin#category", :as => :categories
      resources :users do
        collection do
          get 'deffered'
        end
      end
      resources :datasets, only: [:index, :show, :new, :create, :destroy]
      resources :donorsets, only: [:index, :show, :new, :create, :destroy]
      resources :periods, only: [:index, :show, :new, :create, :edit, :update, :destroy]
      resources :parties do
        collection do
          get 'bulk'
          post 'bulk_update'
        end
      end
      resources :media
      resources :page_contents
    end

    root 'root#index'
    get '/explore' => 'root#explore'
    get '/about' => 'root#about'
    get '/media' => 'root#media'
    get '/download' => 'root#download'
    get '/api' => 'root#api'
    get '/parties' => 'root#parties'
    get '/embed' => 'root#embed'
    get '/share' => 'root#share'
    get 'select/donors' => 'root#select_donors'
    get 'select/parties' => 'root#select_parties'
    get 'explore_filter' => 'root#explore_filter'
    get 'download' => 'root#download'
    get 'download_filter' => 'root#download_filter'
    get 'download_file' => 'root#download_file', defaults: { format: 'zip' }, constraints: { format: 'zip' }

    # get '/read' => 'root#read'
    # get '/read_details' => 'root#read_details'
    # get '/read_donors' => 'root#read_donors'

    # handles /en/fake/path/whatever
    get '*path', to: redirect("/#{I18n.default_locale}")
  end

  # handles /
  get '', to: redirect("/#{I18n.default_locale}")

  # handles /not-a-locale/anything
  get '*path', to: redirect("/#{I18n.default_locale}/%{path}")

  # The priority is based upon order of creation:
  # first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller
  # actions automatically):
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
