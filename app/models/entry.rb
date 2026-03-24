class Entry < ApplicationRecord
  belongs_to :account
  belongs_to :ledger_transaction
end
