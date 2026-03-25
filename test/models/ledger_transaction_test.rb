# frozen_string_literal: true

require "test_helper"

class LedgerTransactionTest < ActiveSupport::TestCase
  test "valid transaction" do
    txn = LedgerTransaction.new(
      idempotency_key: "test_valid_001",
      reference: "Test transaction",
      status: :pending
    )
    assert txn.valid?
  end

  test "requires idempotency_key" do
    txn = LedgerTransaction.new(reference: "Missing key", status: :pending)
    assert_not txn.valid?
    assert_includes txn.errors[:idempotency_key], "can't be blank"
  end

  test "requires unique idempotency_key" do
    LedgerTransaction.create!(
      idempotency_key: "unique_key_test",
      reference: "First",
      status: :pending
    )
    duplicate = LedgerTransaction.new(
      idempotency_key: "unique_key_test",
      reference: "Second",
      status: :pending
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:idempotency_key], "has already been taken"
  end

  test "requires reference" do
    txn = LedgerTransaction.new(idempotency_key: "no_ref_001", status: :pending)
    assert_not txn.valid?
    assert_includes txn.errors[:reference], "can't be blank"
  end

  test "status enum works" do
    txn = ledger_transactions(:pending_txn)
    assert txn.pending?
    txn.posted!
    assert txn.posted?
  end

  test "has many entries" do
    txn = ledger_transactions(:posted_txn)
    assert_respond_to txn, :entries
  end
end
