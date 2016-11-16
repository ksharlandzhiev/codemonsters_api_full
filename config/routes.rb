Rails.application.routes.draw do
  root 'v1/payment_transactions#index'

  scope module: :v1 do
    resources :payment_transactions, format: :json
  end
end
