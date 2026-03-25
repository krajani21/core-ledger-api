# frozen_string_literal: true

class Entry < ApplicationRecord
  belongs_to :account
  belongs_to :ledger_transaction

  # ── Enums ────────────────────────────────────────────────
  enum :entry_type, { debit: "debit", credit: "credit" }

  # ── Validations ──────────────────────────────────────────
  validates :amount,     presence: true, numericality: { greater_than: 0 }
  validates :currency,   presence: true, inclusion: { in: Account::SUPPORTED_CURRENCIES }
  validates :entry_type, presence: true
end
