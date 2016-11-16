class Gateway

  attr_reader :payment_transaction

  APPROVED_CARD_NUMBER = '4200000000000000'.freeze

  def initialize(payment_transaction)
    @payment_transaction = payment_transaction
  end

  def self.process!(transaction)
    new(transaction).process_transaction!
  end

  def process_transaction!
    send("process_#{payment_transaction.transaction_type}_transaction")

    payment_response
  end

  private

  def process_sale_transaction
    payment_transaction.status = transaction_status_for(payment_transaction.card_number)
    payment_transaction.save
  end

  def process_void_transaction
    payment_transaction.status   = PaymentTransaction::STATUS_APPROVED
    payment_transaction.save

    reference_transaction        = PaymentTransaction.find_by_unique_id(payment_transaction.reference_id)
    reference_transaction.update_attribute(:status, PaymentTransaction::STATUS_VOIDED)
  end

  def payment_response
    {
      unique_id:        payment_transaction.unique_id,
      status:           payment_transaction.status,
      usage:            payment_transaction.usage,
      amount:           payment_transaction.amount,
      transaction_time: payment_transaction.created_at,
      message:          response_message(payment_transaction.status, payment_transaction.transaction_type)
    }
  end

  def response_message(status, transaction_type)
    return 'Your transaction has been voided successfully' if successful_void?

    "Your transaction has been #{status}."
  end

  def successful_void?
    payment_transaction.transaction_type == PaymentTransaction::TYPE_VOID &&
      payment_transaction.status == PaymentTransaction::STATUS_APPROVED
  end

  def transaction_status_for(card_number)
    case card_number
    when APPROVED_CARD_NUMBER
      :approved
    else
      :declined
    end
  end
end
