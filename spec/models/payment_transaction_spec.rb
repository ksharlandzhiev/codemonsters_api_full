require 'rails_helper'

describe PaymentTransaction do
  ATTRIBUTES_FOR_PRESENCE_VALIDATION = [:card_holder, :card_number, :usage, :email, :amount, :address]

  let(:transaction) { described_class.new(sale_transaction_params) }

  context '.factory!' do

    context 'step 8' do

      it 'returns payment transaction instance' do
        expect(described_class.factory!( {} )).to be_a PaymentTransaction
      end
    end

    context 'step 9' do

      it 'checks transaction type' do
        expect(PaymentTransaction).to receive(:void_transaction?)

        described_class.factory!( {} )
      end
    end

    context 'step 10' do

      it 'builds sale transaction from params' do
        expect(PaymentTransaction).to receive(:new).with(sale_transaction_params)

        described_class.factory!(sale_transaction_params)
      end
    end

    context 'step 11' do

      it 'builds void transaction from params' do
        expect(PaymentTransaction).to receive(:build_from_reference).with(void_transaction_params)

        described_class.factory!(void_transaction_params)
      end
    end

    context 'when transaction type is void' do

      context 'reference is invalid' do

        it 'returns invalid transaction' do
          transaction = described_class.factory!({reference_id: 'dddd', transaction_type: PaymentTransaction::TYPE_VOID})

          expect(transaction).to_not be_valid
          expect(transaction.errors[:reference_id]).to include 'Invalid reference transaction!'
        end
      end

      context 'reference is valid' do

        it 'builds transaction from reference' do
          transaction.status = 'approved'
          transaction.save

          void_transaction = described_class.factory!({reference_id: transaction.unique_id, transaction_type: PaymentTransaction::TYPE_VOID})

          expect(void_transaction).to be_valid
          expect(void_transaction.card_holder).to eq transaction.card_holder
        end
      end
    end
  end

  context '#process!' do

    context 'step 12' do

      it 'process the transaction through its gateway' do
        expect(Gateway).to receive(:process!).with(transaction)

        transaction.process!
      end
    end
  end

  def sale_transaction_params
    {
      card_holder: 'Panda Panda',
      card_number: '4200000000000000',
      cvv: '123',
      expiration_date: '09/2016',
      email: 'panda@example.com',
      amount: 100,
      usage: 'New por',
      transaction_type: 'sale',
      address: {
                  first_name: 'Panda',
                  last_name: 'Panda',
                  city: 'Sofia'
                }
    }
  end

  def void_transaction_params
    {
      transaction_type: 'void',
      reference_id:     '1234'
    }
  end
end
