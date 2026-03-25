# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate!

      private

      # Expect: Authorization: Bearer <token>
      def authenticate!
        token   = extract_token
        api_key = ApiKey.authenticate(token)

        if api_key.nil?
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def extract_token
        header = request.headers["Authorization"]
        header&.split("Bearer ")&.last
      end

      # Standardised JSON error response
      def render_error(message, status: :unprocessable_entity)
        render json: { error: message }, status: status
      end
    end
  end
end
