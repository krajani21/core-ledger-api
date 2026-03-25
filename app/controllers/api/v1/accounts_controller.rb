# frozen_string_literal: true

module Api
  module V1
    class AccountsController < BaseController
      # GET /api/v1/accounts
      def index
        accounts = Account.order(:name)
        render json: accounts, only: %i[id name currency balance created_at]
      end

      # GET /api/v1/accounts/:id
      def show
        account = Account.find(params[:id])
        render json: account, only: %i[id name currency balance created_at]
      rescue ActiveRecord::RecordNotFound
        render_error("Account not found", status: :not_found)
      end
    end
  end
end
