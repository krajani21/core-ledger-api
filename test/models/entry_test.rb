# frozen_string_literal: true

require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "valid entry" do
    entry = Entry.new(
      account: accounts(:merchant),
      ledger_transaction: ledger_transactions(:posted_txn),
      amount: 50.00,
      currency: "USD",
      entry_type: :debit
    )
    assert entry.valid?
  end

  test "requires amount" do
    entry = Entry.new(
      account: accounts(:merchant),
      ledger_transaction: ledger_transactions(:posted_txn),
      currency: "USD",
      entry_type: :debit
    )
    assert_not entry.valid?
    assert_includes entry.errors[:amount], "can't be blank"
  end

  test "amount must be greater than zero" do
    entry = Entry.new(
      account: accounts(:merchant),
      ledger_transaction: ledger_transactions(:posted_txn),
      amount: -10,
      currency: "USD",
      entry_type: :debit
    )
    assert_not entry.valid?
    assert_includes entry.errors[:amount], "must be greater than 0"
  end

  test "requires currency" do
    entry = Entry.new(
      account: accounts(:merchant),
      ledger_transaction: ledger_transactions(:posted_txn),
      amount: 50,
      entry_type: :debit
    )
    assert_not entry.valid?
    assert_includes entry.errors[:currency], "can't be blank"
  end

  test "rejects unsupported currency" do
    entry = Entry.new(
      account: accounts(:merchant),
      ledger_transaction: ledger_transactions(:posted_txn),
      amount: 50,
      currency: "BTC",
      entry_type: :debit
    )
    assert_not entry.valid?
    assert_includes entry.errors[:currency], "is not included in the list"
  end

  test "entry_type enum works" do
    entry = entries(:debit_entry)
    assert entry.debit?
    assert_not entry.credit?
  end

  test "belongs to account and ledger_transaction" do
    entry = entries(:debit_entry)
    assert_instance_of Account, entry.account
    assert_instance_of LedgerTransaction, entry.ledger_transaction
  end
end
