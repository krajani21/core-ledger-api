# frozen_string_literal: true

# Atomically creates a LedgerTransaction with balanced debit/credit entries
# and updates account balances — the heart of the double-entry ledger.
#
# Usage:
#   result = TransactionService.create(
#     idempotency_key: "order_789_payment",
#     reference:       "Order 789 Checkout",
#     entries: [
#       { account_id: 1, entry_type: "debit",  amount: "100.00", currency: "USD" },
#       { account_id: 2, entry_type: "credit", amount: "100.00", currency: "USD" }
#     ]
#   )
#
#   result.success?          # => true
#   result.transaction       # => LedgerTransaction
#   result.errors            # => [] or ["Debits and credits do not balance"]
#
class TransactionService
  Result = Struct.new(:transaction, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  def self.create(idempotency_key:, reference:, entries:)
    new(idempotency_key:, reference:, entries:).call
  end

  def initialize(idempotency_key:, reference:, entries:)
    @idempotency_key = idempotency_key
    @reference       = reference
    @entry_params    = entries
  end

  def call
    validate_balance!
    process_transaction
  rescue ValidationError => e
    Result.new(transaction: nil, errors: [e.message])
  end

  private

  class ValidationError < StandardError; end

  # ── Step 1: Verify the double-entry invariant ──────────────
  # All amounts are normalised to a single currency (USD) before
  # comparing totals so that multi-currency transactions balance.
  def validate_balance!
    totals = { "debit" => BigDecimal("0"), "credit" => BigDecimal("0") }

    @entry_params.each do |ep|
      normalised = CurrencyService.convert(ep[:amount], from: ep[:currency], to: "USD")
      totals[ep[:entry_type]] += normalised
    end

    return if totals["debit"] == totals["credit"]

    raise ValidationError,
          "Debits (#{totals['debit']}) and credits (#{totals['credit']}) do not balance"
  end

  # ── Step 2: Persist everything inside a single DB transaction ─
  def process_transaction
    ActiveRecord::Base.transaction do
      txn = create_ledger_transaction
      create_entries(txn)
      update_account_balances
      txn.posted!                     # flip status → "posted"

      Result.new(transaction: txn.reload, errors: [])
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.new(transaction: nil, errors: [e.message])
  end

  def create_ledger_transaction
    LedgerTransaction.create!(
      idempotency_key: @idempotency_key,
      reference:       @reference,
      status:          :pending
    )
  end

  def create_entries(txn)
    @entry_params.each do |ep|
      txn.entries.create!(
        account_id: ep[:account_id],
        entry_type: ep[:entry_type],
        amount:     ep[:amount],
        currency:   ep[:currency]
      )
    end
  end

  # Debits decrease account balance, credits increase it.
  def update_account_balances
    @entry_params.each do |ep|
      account = Account.lock.find(ep[:account_id])
      delta   = BigDecimal(ep[:amount].to_s)

      case ep[:entry_type]
      when "debit"  then account.balance -= delta
      when "credit" then account.balance += delta
      end

      account.save!
    end
  end
end
