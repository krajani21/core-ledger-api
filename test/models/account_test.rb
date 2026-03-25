# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account" do
    account = Account.new(name: "test_account", currency: "USD", balance: 0)
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(currency: "USD", balance: 0)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires unique name" do
    Account.create!(name: "unique_test", currency: "USD", balance: 0)
    duplicate = Account.new(name: "unique_test", currency: "USD", balance: 0)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires currency" do
    account = Account.new(name: "no_currency", balance: 0)
    assert_not account.valid?
    assert_includes account.errors[:currency], "can't be blank"
  end

  test "rejects unsupported currency" do
    account = Account.new(name: "bad_currency", currency: "XYZ", balance: 0)
    assert_not account.valid?
    assert_includes account.errors[:currency], "is not included in the list"
  end

  test "balance must be a number" do
    account = Account.new(name: "bad_balance", currency: "USD", balance: "abc")
    assert_not account.valid?
    assert_includes account.errors[:balance], "is not a number"
  end

  test "has many entries" do
    account = accounts(:merchant)
    assert_respond_to account, :entries
  end
end
