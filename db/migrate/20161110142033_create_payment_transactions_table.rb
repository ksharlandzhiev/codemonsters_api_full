class CreatePaymentTransactionsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :payment_transactions do |t|
      t.column   :unique_id,        :string,  limit: 32
      t.column   :status,           :string
      t.column   :card_holder,      :string
      t.column   :card_number,      :string,  limit: 10
      t.column   :email,            :string
      t.column   :amount,           :integer, limit: 4
      t.column   :address,          :text
      t.column   :usage,            :string
      t.column   :transaction_type, :string
      t.column   :reference_id,     :string,  limit: 32
      t.timestamps
    end
  end
end
