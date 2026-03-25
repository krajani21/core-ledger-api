# frozen_string_literal: true

class LedgerTransaction < ApplicationRecord
  has_many :entries, dependent: :restrict_with_error

  # ── Enums ────────────────────────────────────────────────
  enum :status, { pending: "pending", posted: "posted", reversed: "reversed" }

  # ── Validations ──────────────────────────────────────────
  validates :idempotency_key, presence: true, uniqueness: true
  validates :reference,       presence: true
  validates :status,          presence: true
end
