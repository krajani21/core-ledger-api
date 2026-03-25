# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < BaseController
      # POST /api/v1/transactions
      def create
        # TransactionService will be wired in during Phase 5.
        # For now, accept the params and return a placeholder.
        render json: { message: "Transaction creation not yet implemented" }, status: :not_implemented
      end

      # GET /api/v1/transactions/:id
      def show
        transaction = LedgerTransaction.find(params[:id])
        render json: transaction_json(transaction)
      rescue ActiveRecord::RecordNotFound
        render_error("Transaction not found", status: :not_found)
      end

      private

      def transaction_json(txn)
        {
          id: txn.id,
          idempotency_key: txn.idempotency_key,
          reference: txn.reference,
          status: txn.status,
          created_at: txn.created_at,
          entries: txn.entries.map do |entry|
            {
              id: entry.id,
              account_id: entry.account_id,
              entry_type: entry.entry_type,
              amount: entry.amount.to_s,
              currency: entry.currency
            }
          end
        }
      end
    end
  end
end
