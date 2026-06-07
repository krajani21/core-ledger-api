# frozen_string_literal: true

# Seed demo data for development and testing.
# Idempotent — safe to run multiple times via: bin/rails db:seed

puts "Seeding accounts..."

[
  { name: "merchant_revenue",  currency: "USD", opening_balance: 0 },
  { name: "user_wallet",       currency: "CAD", opening_balance: 0 },
  { name: "platform_fees",     currency: "USD", opening_balance: 0 },
  { name: "exchange_holdings", currency: "USD", opening_balance: 0 }
].each do |attrs|
  Account.find_or_create_by!(name: attrs[:name]) do |account|
    account.currency        = attrs[:currency]
    account.opening_balance = attrs[:opening_balance]
  end
end

puts "Seeded #{Account.count} accounts."

# ── API Key ────────────────────────────────────────────────
puts "Seeding API key..."

api_key = ApiKey.find_or_create_by!(name: "development") do |key|
  key.token = "cla_live_dev_test_token_123"
end

puts "Dev API key: #{api_key.token}"
