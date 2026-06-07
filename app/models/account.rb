# frozen_string_literal: true

class Account < ApplicationRecord
  SUPPORTED_CURRENCIES = %w[USD CAD EUR GBP].freeze

  has_many :entries, dependent: :restrict_with_error

  # ── Validations ──────────────────────────────────────────
  validates :name,            presence: true, uniqueness: true
  validates :currency,        presence: true, inclusion: { in: SUPPORTED_CURRENCIES }
  validates :opening_balance, numericality: true

  # Returns the live balance derived entirely from posted entries.
  # opening_balance acts as the account's starting point (typically 0);
  # entries are the authoritative record of every subsequent movement.
  def computed_balance
    credits = entries.where(entry_type: "credit").sum(:amount)
    debits  = entries.where(entry_type: "debit").sum(:amount)
    opening_balance + credits - debits
  end
end
