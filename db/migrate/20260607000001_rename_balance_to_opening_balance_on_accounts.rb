# frozen_string_literal: true

class RenameBalanceToOpeningBalanceOnAccounts < ActiveRecord::Migration[8.1]
  def change
    rename_column :accounts, :balance, :opening_balance
  end
end
