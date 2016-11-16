require 'rails_helper'

describe Gateway do

  let(:transaction) { PaymentTransaction.new(transaction_type: 'sale') }

  context '.process!' do

    context 'step 14', building_steps: true do

      it 'creates new Gateway instance' do
        expect(described_class).to receive(:new).with(transaction)

        described_class.process!(transaction)
      end
    end

    context 'step 15' do

      it 'processing transaction' do
        gateway = instance_double('Gateway')
        expect(described_class).to receive(:new).with(transaction) { gateway }
        expect(gateway).to receive(:process_transaction!)

        described_class.process!(transaction)
      end
    end
  end

  context '#process_transaction!' do

    let(:sale_transaction) { PaymentTransaction.new(sale_transaction_params) }
    let(:gateway)          { described_class.new(sale_transaction) }

    context 'step 16' do

      it 'returns payment response' do
        expect(gateway).to receive(:payment_response)

        gateway.process_transaction!
      end
    end

    context 'step 17' do

      it 'builds response based on transaction type' do
        expect(gateway.process_transaction!).to eq gateway_response(sale_transaction)

        sale_transaction.save
        void_transaction = PaymentTransaction.new(void_transaction_params(sale_transaction.unique_id))
        void_gateway     = Gateway.new(void_transaction)

        expect(void_gateway.process_transaction!).to eq(
          gateway_response(void_transaction, 'Your transaction has been voided successfully'))
      end
    end
  end

  context 'sale transaction' do

    context 'when card number is 4200000000000000' do

      it 'approves the transaction' do
        transaction.card_number = '4200000000000000'

        response = Gateway.process!(transaction)

        expect(transaction.status).to eq 'approved'
        expect(response[:message]).to eq 'Your transaction has been approved.'
      end
    end

    context 'when card number is different' do

      it 'declines the transaction' do
        transaction.card_number = '4111111111111111'

        response = Gateway.process!(transaction)

        expect(transaction.status).to eq 'declined'
        expect(response[:message]).to eq 'Your transaction has been declined.'
      end
    end
  end

  context 'void transaction' do

    before(:each) do
      @sale_transaction = PaymentTransaction.create(sale_transaction_params)
      @void_transaction = PaymentTransaction.create(sale_transaction_params.merge(transaction_type: 'void', reference_id: sale_transaction.unique_id))
    end

    let(:sale_transaction) { @sale_transaction }
    let(:void_transaction) { @void_transaction }

    it 'can be processed successfully' do
      response = Gateway.process!(void_transaction)

      expect(void_transaction.status).to eq 'approved'
      expect(response[:message]).to eq 'Your transaction has been voided successfully'
    end

    it 'changes reference transaction status' do
      Gateway.process!(void_transaction)
      sale_transaction.reload

      expect(sale_transaction.status).to eq 'voided'
    end
  end

  def gateway_response(transaction, message = 'Your transaction has been approved.')
    {
      unique_id:        transaction.unique_id,
      status:           transaction.status,
      usage:            transaction.usage,
      amount:           transaction.amount,
      transaction_time: transaction.created_at,
      message:          message
    }
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
      reference_id: nil,
      address: {
                  first_name: 'Panda',
                  last_name: 'Panda',
                  city: 'Sofia'
                }
    }
  end

  def void_transaction_params(unique_id)
    {
      transaction_type: 'void',
      reference_id:     unique_id
    }
  end
end
