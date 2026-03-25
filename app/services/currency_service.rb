# frozen_string_literal: true

# Handles multi-currency conversion using exchange rates.
#
# For the initial build this uses a hardcoded rate table.
# Swap in a live API client (e.g. exchangerate-api.com) later by
# replacing the RATES hash with an HTTP lookup + Rails.cache.
class CurrencyService
  # Rates relative to USD (1 USD = X of target currency)
  RATES = {
    "USD" => 1.0,
    "CAD" => 1.38,
    "EUR" => 0.92,
    "GBP" => 0.79
  }.freeze

  # Convert an amount from one currency to another.
  #
  #   CurrencyService.convert(100, from: "USD", to: "CAD")
  #   # => 138.0
  #
  # Returns a BigDecimal rounded to 2 decimal places.
  def self.convert(amount, from:, to:)
    return BigDecimal(amount.to_s) if from == to

    rate_from = rate_for(from)
    rate_to   = rate_for(to)

    # Convert: amount_in_from → USD → target currency
    usd_amount    = BigDecimal(amount.to_s) / BigDecimal(rate_from.to_s)
    converted     = usd_amount * BigDecimal(rate_to.to_s)

    converted.round(2)
  end

  # Returns the rate for a given currency, raising if unsupported.
  def self.rate_for(currency)
    RATES.fetch(currency) do
      raise ArgumentError, "Unsupported currency: #{currency}"
    end
  end
end
