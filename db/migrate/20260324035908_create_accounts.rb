class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name
      t.string :currency
      t.decimal :balance

      t.timestamps
    end
  end
end
