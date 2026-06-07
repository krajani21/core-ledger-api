# frozen_string_literal: true

module Api
  module V1
    class AccountsController < BaseController
      # GET /api/v1/accounts
      def index
        accounts = Account.order(:name)
        render json: accounts.map { |a| account_json(a) }
      end

      # GET /api/v1/accounts/:id
      def show
        account = Account.find(params[:id])
        render json: account_json(account)
      rescue ActiveRecord::RecordNotFound
        render_error("Account not found", status: :not_found)
      end

      private

      def account_json(account)
        {
          id:         account.id,
          name:       account.name,
          currency:   account.currency,
          balance:    account.computed_balance,
          created_at: account.created_at
        }
      end
    end
  end
end
