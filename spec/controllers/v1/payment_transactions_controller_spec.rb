require 'rails_helper'

module V1
  describe PaymentTransactionsController do

    let(:card_number)   { '4200000000000000' }
    let(:cvv)           { '123' }
    let(:username)      { 'pandahapva' }
    let(:password)      { 'kachamak' }
    let(:auth_string)   { ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }

    let(:transaction_params) do
      {
        card_number:      card_number,
        cvv:              cvv,
        card_holder:      'Panda Panda',
        email:            'panda@example.com',
        amount:           '500',
        address:          'Panda Street, China',
        usage:            'Coffeemaker',
        transaction_type: 'sale',
        expiration_date:  '06/2019'
      }
    end

    let(:json_payload_sale) { { payment_transaction: transaction_params } }

    let(:permitted_params) do
      ActionController::Parameters.new(transaction_params)
        .permit(transaction_params.keys)
    end

    let(:json_payload_void) do
      { payment_transaction: { transaction_type: 'void',
                               reference_id:     '' } }
    end

    let(:transaction) { instance_double('PaymentTransaction') }

    before(:each) { request.env['HTTP_AUTHORIZATION'] = auth_string }

    context 'authentication' do

      let(:password) { 'invalid' }

      it 'requires HTTP Basic authentication' do
        request.env.delete('HTTP_AUTHORIZATION')

        post :create, params: json_payload_sale

        expect(response.status).to eq 401
        expect(response.body).to include 'Access denied'
      end

      it 'requires valid credentials' do
        post :create, params: json_payload_sale

        expect(response.status).to eq 401
        expect(response.body).to include 'Access denied'
      end
    end

    context '#index' do

      context 'step 1' do

        it 'returns the current UTC timestamp' do
          get :index

          expect(response.body).to eq Time.zone.now.utc.to_s
        end
      end
    end

    context '#create' do

      context 'step 2', building_steps: true do

        it 'returns a JSON response' do
          post :create

          expect(response.content_type).to eq Mime[:json]
        end
      end

      context 'step 3', building_steps: true do

        it 'returns status ok' do
          post :create

          expect(response).to have_http_status :ok
        end
      end

      context 'step 4', building_steps: true do

        it 'created payment transaction by passed params' do
          expect {
            post :create, params: json_payload_sale
          }.to change(PaymentTransaction, :count).by(1)
        end
      end

      context 'step 5', building_steps: true do

        it 'calls the factory method of payment transaction' do
          expect(PaymentTransaction).to receive(:factory!)
            .with(permitted_params)

          post :create, params: json_payload_sale
        end
      end

      context 'step 6', building_steps: true do

        before(:each) do
          expect(PaymentTransaction).to receive(:factory!).with(permitted_params) { transaction }
        end

        it "returns status 'ok' when payment transaction is valid" do
          expect(transaction).to receive(:save) { true }

          post :create, params: json_payload_sale

          expect(response).to have_http_status :ok
        end

        it "returns status 'unprocessable entity' when payment transaction is invalid" do
          expect(transaction).to receive(:save) { false }

          post :create, params: json_payload_sale

          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context 'step 7' do

        before(:each) do
          expect(PaymentTransaction).to receive(:factory!).with(permitted_params) { transaction }
        end

        it 'processes valid transaction' do
          expect(transaction).to receive(:save) { true }
          expect(transaction).to receive(:process!)

          post :create, params: json_payload_sale
        end

        it 'returns error messages for invalid transaction' do
          expect(transaction).to receive(:save) { false }
          expect(transaction).to receive_message_chain(:errors, :messages)

          post :create, params: json_payload_sale
        end
      end

      context 'sale transaction' do

        context 'step 13' do

          context 'when a valid card number is provided' do

            it 'returns response for an approved transaction' do
              post :create, params: json_payload_sale

              response_hash = json_response_for(response.body)

              expect(response.status).to eq 200
              expect(response_hash[:status]).to eq 'approved'
              expect(response_hash[:message]).to eq 'Your transaction has been approved.'
            end
          end

          context 'when an invalid card number is provided' do

            let(:card_number) { '4111111111111111' }

            it 'returns response for a declined transaction' do
              post :create, params: json_payload_sale

              response_hash = json_response_for(response.body)

              expect(response.status).to eq 200
              expect(response_hash[:status]).to eq 'declined'
              expect(response_hash[:message]).to eq 'Your transaction has been declined.'
            end
          end
        end

        context 'when a required parameter is missing' do

          let(:cvv) { '' }

          it 'returns a validation error response' do
            post :create, params: json_payload_sale

            response_hash = json_response_for(response.body)

            expect(response.status).to eq 422
            expect(response_hash[:cvv]).to include "can't be blank"
          end
        end

        context 'when payment processing fails' do

          let(:card_number) { '4012001037484447' }

          it 'returns a processing error response' do
            post :create, params: json_payload_sale

            response_hash = json_response_for(response.body)

            expect(response.status).to eq 200
            expect(response_hash[:status]).to eq 'declined'
            expect(response_hash[:message]).to eq 'Your transaction has been declined.'
          end
        end
      end

      context 'void transaction' do

        context 'when a valid reference transactions is provided' do

          it 'returns response for an approved transaction' do
            reference_transaction = PaymentTransaction.factory!(json_payload_sale[:payment_transaction])
            reference_transaction.save
            reference_transaction.process!

            json_payload_void[:payment_transaction][:reference_id] = reference_transaction.unique_id

            post :create, params: json_payload_void

            response_hash = json_response_for(response.body)

            expect(response.status).to eq 200
            expect(response_hash[:status]).to eq 'approved'
            expect(response_hash[:message]).to eq 'Your transaction has been voided successfully'
          end
        end

        context 'when an invalid reference transactions is provided' do

          it 'returns an error response' do
            post :create, params: json_payload_void

            response_hash = json_response_for(response.body)

            expect(response_hash[:reference_id]).to include 'Invalid reference transaction!'
          end
        end
      end
    end

    private

    def json_response_for(content)
      JSON.parse(content, symbolize_names: true)
    end
  end
end
