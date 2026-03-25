# frozen_string_literal: true

class Account < ApplicationRecord
  SUPPORTED_CURRENCIES = %w[USD CAD EUR GBP].freeze

  has_many :entries, dependent: :restrict_with_error

  # ── Validations ──────────────────────────────────────────
  validates :name,     presence: true, uniqueness: true
  validates :currency, presence: true, inclusion: { in: SUPPORTED_CURRENCIES }
  validates :balance,  numericality: true
end
