module V1
  class PaymentTransactionsController < ApplicationController

    def create
      ##TODO check payment_transaction.rb
      payment_transaction = PaymentTransaction.factory!(payment_transaction_params)

      if payment_transaction.save
        render json: payment_transaction.process!, status: :ok
      else
        render json: payment_transaction.errors.messages, status: :unprocessable_entity
      end
    end

    def index
      render json: Time.zone.now.utc.to_s
    end

    private

    def payment_transaction_params
      params.require(:payment_transaction).permit(:card_number,
                                                  :cvv,
                                                  :card_holder,
                                                  :email,
                                                  :amount,
                                                  :address,
                                                  :usage,
                                                  :transaction_type,
                                                  :expiration_date,
                                                  :reference_id)
    end
  end
end
