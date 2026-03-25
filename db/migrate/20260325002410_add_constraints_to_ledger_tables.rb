# frozen_string_literal: true

class AddConstraintsToLedgerTables < ActiveRecord::Migration[8.1]
  def change
    # ── Accounts ──────────────────────────────────────────────
    change_column_null :accounts, :name,     false
    change_column_null :accounts, :currency, false

    change_column :accounts, :balance, :decimal,
                  precision: 15, scale: 2, null: false, default: 0

    add_index :accounts, :name, unique: true

    # ── Ledger Transactions ───────────────────────────────────
    change_column_null :ledger_transactions, :idempotency_key, false

    change_column :ledger_transactions, :status, :string,
                  null: false, default: "pending"

    # ── Entries ───────────────────────────────────────────────
    change_column :entries, :amount, :decimal,
                  precision: 15, scale: 2, null: false

    change_column_null :entries, :currency,   false
    change_column_null :entries, :entry_type, false
  end
end
