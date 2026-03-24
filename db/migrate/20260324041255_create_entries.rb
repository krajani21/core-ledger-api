class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ledger_transaction, null: false, foreign_key: true
      t.decimal :amount
      t.string :currency
      t.string :entry_type

      t.timestamps
    end
  end
end
