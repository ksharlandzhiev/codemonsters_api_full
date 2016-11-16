class PaymentTransaction < ApplicationRecord

  ATTRIBUTES_FOR_PRESENCE_VALIDATION = [:card_holder, :card_number, :usage, :email, :amount, :address]
  STATUS_APPROVED                    = 'approved'.freeze
  STATUS_VOIDED                      = 'voided'.freeze
  TYPE_VOID                          = 'void'.freeze
  TYPE_SALE                          = 'sale'.freeze
  SUPPORTED_TRANSACTION_TYPES        = [TYPE_SALE, TYPE_VOID]

  validates_presence_of ATTRIBUTES_FOR_PRESENCE_VALIDATION, if: lambda { sale_transaction? }
  validates_presence_of [:cvv, :expiration_date], if: lambda { sale_transaction? }

  validates :transaction_type, inclusion: { in: SUPPORTED_TRANSACTION_TYPES }
  validates :amount, numericality: { only_integer: true, greater_than: 0 }, if: lambda { sale_transaction? }

  validates_format_of :email,       with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, if: lambda { sale_transaction? }
  validates_format_of :card_number, with: /\A[0-9]{13,19}\Z/i, if: lambda { sale_transaction? }
  validates_format_of :cvv,         with: /\A[0-9]{3,4}\Z/i, if: lambda { sale_transaction? }

  validate :validates_approved_reference, unless: lambda { sale_transaction? }

  scope :approved_reference_transaction, -> (reference_id) { where(unique_id: reference_id,
                                                                   status: STATUS_APPROVED) }

  before_save :generate_unique_id

  attr_accessor :cvv, :expiration_date

  def self.factory!(params)
    ##TODO 2 transaction types sale and void. Use # void_transaction?
    # method should return PaymentTransaction instance without save it to DB
    if void_transaction?(params)
      build_from_reference(params)
    else
      PaymentTransaction.new(params)
    end
  end

  def process!
    ##TODO pass transaction to Gateway to be processed
    Gateway.process!(self)
  end

  private

  def self.void_transaction?(params)
    params[:transaction_type] == TYPE_VOID && params.key?(:reference_id)
  end

  def sale_transaction?
    self.transaction_type == TYPE_SALE
  end

  def self.build_from_reference(params)
    reference_id = params[:reference_id]
    reference_transaction = approved_reference_transaction(reference_id).first

    if reference_transaction.present?
      return PaymentTransaction.new(params.merge(void_attributes_for(reference_transaction)))
    end

    PaymentTransaction.new(params)
  end

  def self.void_attributes_for(reference_transaction)
    reference_transaction.attributes.slice('card_holder', 'usage', 'email', 'amount', 'address')
  end

  def generate_unique_id
    self.unique_id = SecureRandom.hex(16)
  end

  def validates_approved_reference
    reference_transaction = PaymentTransaction.approved_reference_transaction(self.reference_id).first

    self.errors[:reference_id] << 'Invalid reference transaction!' unless reference_transaction.present?
  end
end
