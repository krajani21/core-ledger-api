module CoreLedger
  class TransactionValidator
    class ImbalancedTransactionError < StandardError; end
    class InvalidCurrencyError < StandardError; end

    # Validates if a set of entries forms a balanced double-entry transaction.
    # Entries should be an array of hashes: [{ amount: 100.0, type: :debit, currency: 'USD' }, ...]
    def self.validate!(entries)
      raise ArgumentError, "A transaction must have at least 2 entries" if entries.length < 2

      # Ensure all entries have the same currency for a basic validation
      # (In a multi-currency system, we would convert to a base currency first)
      currencies = entries.map { |e| e[:currency] }.uniq
      if currencies.length > 1
        raise InvalidCurrencyError, "Multi-currency transactions require a conversion rate, entries have: #{currencies.join(', ')}"
      end

      total_debits = 0.0
      total_credits = 0.0

      entries.each do |entry|
        if entry[:type] == :debit
          total_debits += entry[:amount]
        elsif entry[:type] == :credit
          total_credits += entry[:amount]
        else
          raise ArgumentError, "Entry type must be :debit or :credit"
        end
      end

      precision = 2 # Handle float math precision issues for currencies
      if total_debits.round(precision) != total_credits.round(precision)
        raise ImbalancedTransactionError, "Transaction imbalanced! Debits: #{total_debits}, Credits: #{total_credits}"
      end

      true
    end
  end
end

# Example Usage (You can run this via terminal: ruby transaction_validator.rb)
if __FILE__ == $0
  puts "Testing a valid transaction..."
  valid_entries = [
    { amount: 50.00, type: :debit,  currency: 'USD' },
    { amount: 50.00, type: :credit, currency: 'USD' }
  ]
  CoreLedger::TransactionValidator.validate!(valid_entries)
  puts "Valid transaction passed! ✅"

  puts "\nTesting an invalid transaction..."
  invalid_entries = [
    { amount: 50.00, type: :debit,  currency: 'USD' },
    { amount: 40.00, type: :credit, currency: 'USD' }
  ]
  begin
    CoreLedger::TransactionValidator.validate!(invalid_entries)
  rescue CoreLedger::TransactionValidator::ImbalancedTransactionError => e
    puts "Invalid transaction correctly caught! ❌ (Error: #{e.message})"
  end
end
