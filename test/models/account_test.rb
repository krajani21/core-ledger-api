# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account" do
    account = Account.new(name: "test_account", currency: "USD", opening_balance: 0)
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(currency: "USD", opening_balance: 0)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    Account.create!(name: "unique_test", currency: "USD", opening_balance: 0)
    duplicate = Account.new(name: "unique_test", currency: "USD", opening_balance: 0)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires currency" do
    account = Account.new(name: "no_currency", opening_balance: 0)
    assert_not account.valid?
    assert_includes account.errors[:currency], "can't be blank"
  end

  test "rejects unsupported currency" do
    account = Account.new(name: "bad_currency", currency: "XYZ", opening_balance: 0)
    assert_not account.valid?
    assert_includes account.errors[:currency], "is not included in the list"
  end

  test "opening_balance must be a number" do
    account = Account.new(name: "bad_balance", currency: "USD", opening_balance: "abc")
    assert_not account.valid?
    assert_includes account.errors[:opening_balance], "is not a number"
  end

  test "computed_balance reflects entries" do
    account = accounts(:merchant)
    # merchant fixture: opening_balance 1000, one debit entry of 100 USD
    assert_equal 900.0, account.computed_balance
  end

  test "has many entries" do
    account = accounts(:merchant)
    assert_respond_to account, :entries
  end
end
