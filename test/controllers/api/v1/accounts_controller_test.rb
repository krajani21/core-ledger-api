# frozen_string_literal: true

require "test_helper"

class Api::V1::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = api_keys(:dev_key).token
    @auth  = { "Authorization" => "Bearer #{@token}" }
  end

  test "GET /api/v1/accounts returns all accounts" do
    get api_v1_accounts_url, headers: @auth
    assert_response :success

    body = JSON.parse(response.body)
    assert_kind_of Array, body
    assert body.length >= 2
  end

  test "GET /api/v1/accounts/:id returns account" do
    account = accounts(:merchant)
    get api_v1_account_url(account), headers: @auth
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal account.name, body["name"]
    assert_equal account.currency, body["currency"]
  end

  test "GET /api/v1/accounts/:id returns 404 for missing account" do
    get api_v1_account_url(id: 999_999), headers: @auth
    assert_response :not_found
  end

  test "returns 401 without auth header" do
    get api_v1_accounts_url
    assert_response :unauthorized
  end

  test "returns 401 with inactive API key" do
    inactive_token = api_keys(:inactive_key).token
    get api_v1_accounts_url, headers: { "Authorization" => "Bearer #{inactive_token}" }
    assert_response :unauthorized
  end
end
