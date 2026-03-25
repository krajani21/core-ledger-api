# frozen_string_literal: true

require "test_helper"

class TransactionServiceTest < ActiveSupport::TestCase
  setup do
    @merchant = accounts(:merchant)
    @wallet   = accounts(:wallet)
  end

  test "creates a balanced transaction successfully" do
    result = TransactionService.create(
      idempotency_key: "service_test_001",
      reference: "Balanced payment",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "50.00", currency: "USD" },
        { account_id: @wallet.id,   entry_type: "credit", amount: "50.00", currency: "USD" }
      ]
    )

    assert result.success?
    assert_equal "posted", result.transaction.status
    assert_equal 2, result.transaction.entries.count
  end

  test "rejects imbalanced transaction" do
    result = TransactionService.create(
      idempotency_key: "service_test_002",
      reference: "Imbalanced payment",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "100.00", currency: "USD" },
        { account_id: @wallet.id,   entry_type: "credit", amount: "50.00",  currency: "USD" }
      ]
    )

    assert_not result.success?
    assert_includes result.errors.first, "do not balance"
  end

  test "updates account balances correctly" do
    merchant_before = @merchant.balance
    wallet_before   = @wallet.balance

    TransactionService.create(
      idempotency_key: "service_test_003",
      reference: "Balance update test",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "25.00", currency: "USD" },
        { account_id: @wallet.id,   entry_type: "credit", amount: "25.00", currency: "USD" }
      ]
    )

    @merchant.reload
    @wallet.reload

    assert_equal merchant_before - 25, @merchant.balance
    assert_equal wallet_before + 25,   @wallet.balance
  end

  test "transaction is atomic — rolls back on failure" do
    merchant_before = @merchant.balance

    # Force a failure by using a non-existent account ID
    result = TransactionService.create(
      idempotency_key: "service_test_004",
      reference: "Atomic failure test",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "50.00", currency: "USD" },
        { account_id: 999_999,      entry_type: "credit", amount: "50.00", currency: "USD" }
      ]
    )

    assert_not result.success?
    @merchant.reload
    assert_equal merchant_before, @merchant.balance
  end

  test "multi-currency transaction balances through USD conversion" do
    # 100 USD debit should equal 138 CAD credit (rate: 1 USD = 1.38 CAD)
    result = TransactionService.create(
      idempotency_key: "service_test_005",
      reference: "Multi-currency test",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "100.00", currency: "USD" },
        { account_id: @wallet.id,   entry_type: "credit", amount: "138.00", currency: "CAD" }
      ]
    )

    assert result.success?
    assert_equal "posted", result.transaction.status
  end
end
