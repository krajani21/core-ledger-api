# frozen_string_literal: true

require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token    = api_keys(:dev_key).token
    @auth     = { "Authorization" => "Bearer #{@token}" }
    @merchant = accounts(:merchant)
    @wallet   = accounts(:wallet)
  end

  test "POST /api/v1/transactions creates a balanced transaction" do
    payload = {
      idempotency_key: "ctrl_test_001",
      reference: "Controller test payment",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "75.00", currency: "USD" },
        { account_id: @wallet.id,   entry_type: "credit", amount: "75.00", currency: "USD" }
      ]
    }

    post api_v1_transactions_url, params: payload, headers: @auth, as: :json
    assert_response :created

    body = JSON.parse(response.body)
    assert_equal "posted", body["status"]
    assert_equal 2, body["entries"].length
  end

  test "POST /api/v1/transactions rejects imbalanced entries" do
    payload = {
      idempotency_key: "ctrl_test_002",
      reference: "Imbalanced test",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "100.00", currency: "USD" },
        { account_id: @wallet.id,   entry_type: "credit", amount: "50.00",  currency: "USD" }
      ]
    }

    post api_v1_transactions_url, params: payload, headers: @auth, as: :json
    assert_response :unprocessable_entity
  end

  test "POST /api/v1/transactions returns existing for duplicate idempotency_key" do
    payload = {
      idempotency_key: "ctrl_test_003",
      reference: "Idempotency test",
      entries: [
        { account_id: @merchant.id, entry_type: "debit",  amount: "30.00", currency: "USD" },
        { account_id: @wallet.id,   entry_type: "credit", amount: "30.00", currency: "USD" }
      ]
    }

    # First request → 201
    post api_v1_transactions_url, params: payload, headers: @auth, as: :json
    assert_response :created
    first_body = JSON.parse(response.body)

    # Duplicate request → 200 with same transaction
    post api_v1_transactions_url, params: payload, headers: @auth, as: :json
    assert_response :ok
    second_body = JSON.parse(response.body)

    assert_equal first_body["id"], second_body["id"]
  end

  test "GET /api/v1/transactions/:id returns transaction with entries" do
    txn = ledger_transactions(:posted_txn)
    get api_v1_transaction_url(txn), headers: @auth
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal txn.idempotency_key, body["idempotency_key"]
    assert_kind_of Array, body["entries"]
  end

  test "GET /api/v1/transactions/:id returns 404 for missing" do
    get api_v1_transaction_url(id: 999_999), headers: @auth
    assert_response :not_found
  end

  test "returns 401 without auth header" do
    post api_v1_transactions_url, params: {}, as: :json
    assert_response :unauthorized
  end
end
