class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :idempotency_key
      t.string :reference
      t.string :status

      t.timestamps
    end
    add_index :transactions, :idempotency_key, unique: true
  end
end
