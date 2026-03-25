# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      # Shared API v1 logic lives here.
      # Authentication will be added in Phase 6.

      private

      # Standardised JSON error response
      def render_error(message, status: :unprocessable_entity)
        render json: { error: message }, status: status
      end
    end
  end
end
