# frozen_string_literal: true

class ApiKey < ApplicationRecord
  has_secure_token :token

  # ── Validations ──────────────────────────────────────────
  validates :name, presence: true

  # ── Scopes ───────────────────────────────────────────────
  scope :active, -> { where(active: true) }

  # Look up a key by its raw token, returning nil if not found or inactive.
  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    active.find_by(token: raw_token)
  end
end
