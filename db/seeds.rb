# frozen_string_literal: true

# Seed demo accounts for development and testing.
# Idempotent — safe to run multiple times via: bin/rails db:seed

puts "Seeding accounts..."

[
  { name: "merchant_revenue",  currency: "USD", balance: 0 },
  { name: "user_wallet",       currency: "CAD", balance: 0 },
  { name: "platform_fees",     currency: "USD", balance: 0 },
  { name: "exchange_holdings", currency: "USD", balance: 0 }
].each do |attrs|
  Account.find_or_create_by!(name: attrs[:name]) do |account|
    account.currency = attrs[:currency]
    account.balance  = attrs[:balance]
  end
end

puts "Seeded #{Account.count} accounts."
