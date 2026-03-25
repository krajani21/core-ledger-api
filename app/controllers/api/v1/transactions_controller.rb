# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < BaseController
      # POST /api/v1/transactions
      def create
        result = TransactionService.create(
          idempotency_key: transaction_params[:idempotency_key],
          reference:       transaction_params[:reference],
          entries:         entry_params
        )

        if result.success?
          render json: transaction_json(result.transaction), status: :created
        else
          render_error(result.errors, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/transactions/:id
      def show
        transaction = LedgerTransaction.find(params[:id])
        render json: transaction_json(transaction)
      rescue ActiveRecord::RecordNotFound
        render_error("Transaction not found", status: :not_found)
      end

      private

      def transaction_params
        params.permit(:idempotency_key, :reference, entries: %i[account_id entry_type amount currency])
      end

      def entry_params
        (transaction_params[:entries] || []).map do |ep|
          ep.to_h.symbolize_keys
        end
      end

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
