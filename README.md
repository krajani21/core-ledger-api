<![CDATA[# 💰 Core Ledger API

> A production-grade, double-entry accounting ledger engine built with Ruby on Rails — the same kind of financial infrastructure that powers companies like Stripe, Shopify, and WealthSimple.

[![Ruby](https://img.shields.io/badge/Ruby-3.2+-red?logo=ruby)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1+-red?logo=rubyonrails)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7+-red?logo=redis)](https://redis.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Data Model](#data-model)
- [API Design](#api-design)
- [Multi-Currency Engine](#multi-currency-engine)
- [Webhook System](#webhook-system)
- [Real-Time Dashboard](#real-time-dashboard)
- [Authentication & Security](#authentication--security)
- [Background Jobs](#background-jobs)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Project Structure](#project-structure)

---

## Overview

Core Ledger API is a **double-entry bookkeeping system** exposed as a RESTful JSON API. It provides the foundational financial infrastructure that fintech products are built on — recording transactions, maintaining account balances, handling multi-currency conversions, and notifying external systems via webhooks.

### Why Double-Entry?

Every financial movement creates **two entries** that sum to zero — a debit and a credit. This guarantees that books are always balanced and makes it trivial to audit the flow of money.

```
Customer pays $50 for a product:
  ┌──────────────────────┐      ┌──────────────────────┐
  │  Customer Account    │      │  Merchant Account    │
  │  Credit: -$50.00     │ ──── │  Debit:  +$50.00     │
  └──────────────────────┘      └──────────────────────┘
                    Net Effect = $0.00 ✓
```

### Key Features

| Feature | Description |
|---|---|
| **Double-Entry Bookkeeping** | Every transaction creates balanced debit/credit entries — books always sum to zero |
| **Multi-Currency Support** | Handle USD, CAD, EUR, GBP with real-time exchange rates and automatic conversion |
| **RESTful JSON API** | Versioned API (`/api/v1/`) with pagination, filtering, and idempotency keys |
| **Webhook Delivery System** | Notify external services of events with HMAC-signed payloads, exponential backoff retries |
| **Real-Time Dashboard** | Live-updating UI powered by Hotwire (Turbo Streams + Stimulus) — no page refreshes |
| **Idempotent Transactions** | Safely retry requests without double-processing via idempotency keys |
| **Comprehensive Audit Trail** | Every state change is immutable and traceable |

---

## Architecture

### High-Level System Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Core Ledger API                              │
│                                                                     │
│  ┌──────────┐    ┌──────────────┐    ┌───────────────────────────┐  │
│  │  Rails    │    │   Sidekiq     │    │     Hotwire Dashboard     │  │
│  │  API      │───▶│  Background   │    │  (Turbo Streams + Stim.) │  │
│  │  Layer    │    │  Jobs         │    └───────────┬───────────────┘  │
│  └────┬─────┘    └──────┬───────┘                │                  │
│       │                 │                        │                  │
│       ▼                 ▼                        ▼                  │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    Service Layer                                │ │
│  │  TransactionService │ CurrencyService │ WebhookService         │ │
│  │  AccountService     │ BalanceService  │ AuditService            │ │
│  └────────┬────────────────────┬──────────────────┬───────────────┘ │
│           │                    │                  │                  │
│           ▼                    ▼                  ▼                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │  PostgreSQL   │    │    Redis      │    │  External    │          │
│  │  (Primary DB) │    │  (Cache/Jobs) │    │  Rate API    │          │
│  └──────────────┘    └──────────────┘    └──────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

### Request Lifecycle

```
Incoming API Request
        │
        ▼
┌─────────────────┐
│  Authentication  │──▶ Verify API key via `Authorization` header
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Rate Limiter   │──▶ Rack::Attack (100 req/min per key)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Controller     │──▶ Validate params, check idempotency key
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Service Layer  │──▶ Business logic: create entries, convert currency
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   DB Transaction │──▶ Atomic write: entries + balance updates in one TX
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Async Dispatch  │──▶ Enqueue webhook delivery + Turbo Stream broadcast
└────────┬────────┘
         │
         ▼
    JSON Response
```

---

## Data Model

### Entity Relationship Diagram

```
┌───────────────┐       ┌───────────────────┐       ┌───────────────────┐
│    Account     │       │    Transaction     │       │      Entry        │
├───────────────┤       ├───────────────────┤       ├───────────────────┤
│ id            │       │ id                │       │ id                │
│ name          │       │ idempotency_key   │       │ transaction_id    │──▶ Transaction
│ currency      │       │ reference         │       │ account_id        │──▶ Account
│ balance       │       │ status            │       │ entry_type        │ (debit/credit)
│ account_type  │       │ metadata (jsonb)  │       │ amount            │
│ created_at    │       │ created_at        │       │ currency          │
│ updated_at    │       │ updated_at        │       │ created_at        │
└───────┬───────┘       └─────────┬─────────┘       └───────────────────┘
        │                         │
        │  1 ◀──────────────▶ N   │  1 ◀──────────────▶ 2+
        │                         │
        ▼                         │
┌───────────────────┐             │
│   Balance Cache    │             │
├───────────────────┤             │
│ account_id        │             │
│ currency          │             │
│ available_balance │             │
│ pending_balance   │             │
│ last_updated_at   │             │
└───────────────────┘             │
                                  │
        ┌─────────────────────────┘
        │
        ▼
┌───────────────────┐       ┌───────────────────┐
│  WebhookEndpoint   │       │  WebhookDelivery   │
├───────────────────┤       ├───────────────────┤
│ id                │       │ id                │
│ url               │       │ webhook_endpoint_id│──▶ WebhookEndpoint
│ secret            │       │ event_type        │
│ events (array)    │       │ payload (jsonb)   │
│ active            │       │ status            │ (pending/success/failed)
│ created_at        │       │ response_code     │
│ updated_at        │       │ attempts          │
└───────────────────┘       │ next_retry_at     │
                            │ created_at        │
                            └───────────────────┘

┌───────────────────┐       ┌───────────────────┐
│   ExchangeRate     │       │     ApiKey         │
├───────────────────┤       ├───────────────────┤
│ id                │       │ id                │
│ from_currency     │       │ name              │
│ to_currency       │       │ key_digest        │
│ rate              │       │ last_used_at      │
│ fetched_at        │       │ active            │
│ source            │       │ created_at        │
└───────────────────┘       └───────────────────┘
```

### Key Constraints

- **Entries always balance**: For every `Transaction`, the sum of all debit entries must equal the sum of all credit entries.
- **Immutable entries**: Once written, entries are never updated or deleted — only new correcting entries are created (reversals).
- **Optimistic locking**: Account balances use `lock_version` to prevent lost updates under concurrent writes.
- **Idempotency**: Duplicate requests with the same `idempotency_key` return the original response instead of creating duplicate transactions.

### Schema Highlights

```ruby
# db/migrate/xxx_create_accounts.rb
create_table :accounts do |t|
  t.string   :name,          null: false
  t.string   :currency,      null: false, default: "USD"
  t.string   :account_type,  null: false  # asset, liability, equity, revenue, expense
  t.decimal  :balance,       precision: 20, scale: 4, default: 0
  t.integer  :lock_version,  default: 0
  t.timestamps
end
add_index :accounts, :name, unique: true

# db/migrate/xxx_create_transactions.rb
create_table :transactions do |t|
  t.string   :idempotency_key
  t.string   :reference
  t.string   :status,    null: false, default: "pending"  # pending, posted, reversed
  t.jsonb    :metadata,  default: {}
  t.timestamps
end
add_index :transactions, :idempotency_key, unique: true

# db/migrate/xxx_create_entries.rb
create_table :entries do |t|
  t.references :transaction, null: false, foreign_key: true
  t.references :account,     null: false, foreign_key: true
  t.string     :entry_type,  null: false  # debit, credit
  t.decimal    :amount,      precision: 20, scale: 4, null: false
  t.string     :currency,    null: false
  t.timestamps
end
add_index :entries, [:transaction_id, :account_id]
```

---

## API Design

The API follows REST conventions with versioned endpoints under `/api/v1/`. All responses are JSON.

### Authentication

Every request requires an API key in the `Authorization` header:

```
Authorization: Bearer cla_live_xxxxxxxxxxxxxxxxxxxxxxxx
```

### Endpoints

#### Accounts

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/accounts` | Create a new account |
| `GET` | `/api/v1/accounts` | List all accounts (paginated) |
| `GET` | `/api/v1/accounts/:id` | Get account details + balance |
| `GET` | `/api/v1/accounts/:id/entries` | List entries for an account |

#### Transactions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/transactions` | Create a new transaction |
| `GET` | `/api/v1/transactions` | List transactions (filterable) |
| `GET` | `/api/v1/transactions/:id` | Get transaction with entries |
| `POST` | `/api/v1/transactions/:id/reverse` | Reverse a posted transaction |

#### Webhooks

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/webhook_endpoints` | Register a webhook endpoint |
| `GET` | `/api/v1/webhook_endpoints` | List registered endpoints |
| `DELETE` | `/api/v1/webhook_endpoints/:id` | Remove an endpoint |
| `GET` | `/api/v1/webhook_deliveries` | List delivery attempts |

#### Exchange Rates

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/exchange_rates` | Get current rates |
| `GET` | `/api/v1/exchange_rates/convert` | Convert an amount between currencies |

### Example: Create a Transaction

**Request:**

```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer cla_live_xxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "idempotency_key": "txn_abc123",
    "reference": "Order #1042 payment",
    "entries": [
      {
        "account_id": 1,
        "entry_type": "debit",
        "amount": "50.00",
        "currency": "USD"
      },
      {
        "account_id": 2,
        "entry_type": "credit",
        "amount": "50.00",
        "currency": "USD"
      }
    ],
    "metadata": {
      "order_id": "1042",
      "source": "shopify"
    }
  }'
```

**Response (201 Created):**

```json
{
  "data": {
    "id": 1,
    "idempotency_key": "txn_abc123",
    "reference": "Order #1042 payment",
    "status": "posted",
    "entries": [
      {
        "id": 1,
        "account_id": 1,
        "account_name": "merchant_revenue",
        "entry_type": "debit",
        "amount": "50.0000",
        "currency": "USD"
      },
      {
        "id": 2,
        "account_id": 2,
        "account_name": "customer_payments",
        "entry_type": "credit",
        "amount": "50.0000",
        "currency": "USD"
      }
    ],
    "metadata": {
      "order_id": "1042",
      "source": "shopify"
    },
    "created_at": "2026-03-18T12:00:00Z"
  }
}
```

### Error Handling

All errors follow a consistent format:

```json
{
  "error": {
    "code": "unbalanced_entries",
    "message": "Debit and credit amounts must be equal. Debits: 50.00, Credits: 45.00",
    "status": 422
  }
}
```

| Error Code | HTTP Status | Description |
|---|---|---|
| `unbalanced_entries` | 422 | Debit/credit totals don't match |
| `insufficient_balance` | 422 | Account balance too low for debit |
| `duplicate_idempotency_key` | 409 | Transaction already exists (returns original) |
| `account_not_found` | 404 | Referenced account doesn't exist |
| `currency_mismatch` | 422 | Entry currency doesn't match account currency |
| `invalid_api_key` | 401 | Missing or invalid API key |
| `rate_limit_exceeded` | 429 | Too many requests |

### Pagination

List endpoints support cursor-based pagination:

```
GET /api/v1/transactions?per_page=25&cursor=eyJpZCI6MTAwfQ==
```

```json
{
  "data": [ ... ],
  "meta": {
    "has_more": true,
    "next_cursor": "eyJpZCI6MTI1fQ=="
  }
}
```

---

## Multi-Currency Engine

### How It Works

1. Each **Account** has a home currency (e.g., `CAD`).
2. Each **Entry** records the currency of the movement.
3. When a transaction involves different currencies, the `CurrencyService` fetches the real-time exchange rate and records the conversion.

### Conversion Flow

```
Customer (USD account) pays Merchant (CAD account) $50 USD
        │
        ▼
┌─────────────────────┐
│  CurrencyService     │
│  Fetch rate: 1 USD   │──▶  External Rate API (cached in Redis, 1hr TTL)
│  = 1.36 CAD          │
└────────┬────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  Transaction Created:                            │
│    Entry 1: Credit $50.00 USD from Customer      │
│    Entry 2: Debit  $68.00 CAD to Merchant        │
│    Exchange Rate: 1.3600 (USD → CAD)             │
│    Rate Source: "exchangerate-api"                │
└─────────────────────────────────────────────────┘
```

### Rate Caching Strategy

```ruby
class CurrencyService
  CACHE_TTL = 1.hour

  def rate(from:, to:)
    Rails.cache.fetch("exchange_rate:#{from}:#{to}", expires_in: CACHE_TTL) do
      fetch_live_rate(from, to).tap do |rate|
        ExchangeRate.create!(from_currency: from, to_currency: to, rate: rate, source: provider_name)
      end
    end
  end
end
```

- Rates cached in **Redis** with 1-hour TTL
- Every fetched rate is persisted to `exchange_rates` table for historical audit
- Fallback to most recent DB rate if external API is down

---

## Webhook System

### Event Types

| Event | Trigger |
|---|---|
| `transaction.created` | New transaction posted |
| `transaction.reversed` | Transaction reversed |
| `account.created` | New account opened |
| `account.balance_updated` | Account balance changed |

### Delivery Mechanism

```
Event Occurs (e.g., transaction.created)
        │
        ▼
┌─────────────────────────┐
│  WebhookDispatchJob      │ ◀── Sidekiq (async)
│  (Background Job)        │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Build Payload           │
│  {                       │
│    "event": "txn.created"│
│    "data": { ... },      │
│    "timestamp": "..."    │
│  }                       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Sign with HMAC-SHA256   │──▶ X-Ledger-Signature header
│  (endpoint.secret)       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐      ┌──────────────────┐
│  HTTP POST to endpoint   │─────▶│  External Service │
│  Timeout: 10 seconds     │      └──────────────────┘
└────────┬────────────────┘
         │
    Success (2xx)?
    ├── Yes ──▶ Mark delivery as "success"
    └── No  ──▶ Retry with exponential backoff
```

### Retry Strategy

| Attempt | Delay | Cumulative Wait |
|---------|-------|-----------------|
| 1 | Immediate | 0 |
| 2 | 1 minute | 1 min |
| 3 | 5 minutes | 6 min |
| 4 | 30 minutes | 36 min |
| 5 | 2 hours | ~2.5 hrs |

After 5 failed attempts, the delivery is marked as `failed` and the endpoint is flagged for review.

### Signature Verification (Consumer Side)

```ruby
# The receiving app verifies the webhook is authentic:
expected = OpenSSL::HMAC.hexdigest("SHA256", endpoint_secret, raw_body)
if Rack::Utils.secure_compare(expected, request.headers["X-Ledger-Signature"])
  # Verified — process the webhook
end
```

---

## Real-Time Dashboard

The dashboard is a server-rendered Rails view powered by **Hotwire** (Turbo + Stimulus) — the same frontend stack built and used by Shopify.

### Dashboard Features

| Section | What It Shows | Update Mechanism |
|---|---|---|
| **Transaction Feed** | Live stream of transactions as they post | Turbo Stream (WebSocket broadcast) |
| **Account Balances** | Current balance for all accounts | Turbo Frame (auto-refresh) |
| **Webhook Monitor** | Delivery statuses, retry attempts, failures | Turbo Stream |
| **Currency Rates** | Current cached exchange rates | Stimulus polling (every 60s) |

### How Real-Time Works

```
Transaction Created in DB
        │
        ▼
┌───────────────────────────┐
│  after_commit callback     │
│  broadcast_append_to       │
│    "transactions"          │
│                            │
│  Turbo::StreamsChannel     │──▶ ActionCable WebSocket
└───────────────────────────┘          │
                                       ▼
                              ┌─────────────────┐
                              │  Browser (User)   │
                              │  DOM auto-updated │
                              │  No JS required   │
                              └─────────────────┘
```

```ruby
# app/models/transaction.rb
class Transaction < ApplicationRecord
  after_commit :broadcast_to_dashboard, on: :create

  private

  def broadcast_to_dashboard
    broadcast_append_to "transactions",
      partial: "transactions/transaction",
      target: "transactions_list"
  end
end
```

---

## Authentication & Security

### API Key Authentication

- API keys are hashed (`bcrypt`) before storage — raw keys are never persisted
- Keys are generated via a Rake task or the dashboard and shown **once**
- Each request is authenticated via `before_action` in the API base controller

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_key!

  private

  def authenticate_api_key!
    token = request.headers["Authorization"]&.remove("Bearer ")
    @current_api_key = ApiKey.find_by_token(token)
    render_error("invalid_api_key", "Invalid API key", 401) unless @current_api_key
  end
end
```

### Rate Limiting

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("api/ip", limit: 100, period: 60) do |req|
  req.ip if req.path.start_with?("/api/")
end
```

### Additional Security Measures

- **HMAC webhook signatures** — prevents payload tampering
- **Database-level constraints** — ensures data integrity even if app logic fails
- **Parameterized queries** — ActiveRecord prevents SQL injection by default
- **Idempotency keys** — prevents duplicate financial operations
- **Optimistic locking** — prevents race conditions on balance updates

---

## Background Jobs

Powered by **Sidekiq** + **Redis**.

| Job | Queue | Purpose |
|---|---|---|
| `WebhookDeliveryJob` | `webhooks` | Deliver webhook payloads to endpoints |
| `WebhookRetryJob` | `webhooks` | Retry failed webhook deliveries |
| `ExchangeRateSyncJob` | `default` | Periodically refresh cached exchange rates |
| `BalanceRecalculationJob` | `critical` | Recalculate account balance from entries (consistency check) |

```ruby
# app/jobs/webhook_delivery_job.rb
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(webhook_delivery_id)
    delivery = WebhookDelivery.find(webhook_delivery_id)
    WebhookService.new.deliver(delivery)
  end
end
```

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Language** | Ruby 3.2+ | Required by Shopify/Stripe/WS roles |
| **Framework** | Rails 7.1+ | Convention-over-config, batteries included |
| **Database** | PostgreSQL 15+ | ACID compliance, `jsonb`, advisory locks |
| **Cache / Jobs** | Redis 7+ | Sidekiq backend, rate caching, ActionCable |
| **Background Jobs** | Sidekiq | Reliable async processing with retries |
| **Real-Time** | Hotwire (Turbo + Stimulus) | Server-side reactivity, built by Shopify |
| **WebSocket** | ActionCable | WebSocket layer for Turbo Streams |
| **Rate Limiting** | Rack::Attack | Middleware-level request throttling |
| **Testing** | RSpec + FactoryBot + VCR | Comprehensive test suite |
| **API Serialization** | Blueprinter | Fast, flexible JSON serialization |
| **HTTP Client** | Faraday | Webhook delivery + rate API calls |

---

## Getting Started

### Prerequisites

- Ruby 3.2+
- Rails 7.1+
- PostgreSQL 15+
- Redis 7+

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/core-ledger-api.git
cd core-ledger-api

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start Redis (required for Sidekiq and caching)
redis-server

# Start Sidekiq (background jobs)
bundle exec sidekiq

# Start the server
bin/dev
```

### Seed Data

The seed file creates:
- 5 demo accounts (merchant, customer, fees, etc.) across USD and CAD
- 1 API key (printed to console on seed)
- 2 webhook endpoints
- 10 sample transactions

---

## Testing

```bash
# Run the full test suite
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/transaction_spec.rb
bundle exec rspec spec/services/currency_service_spec.rb
bundle exec rspec spec/requests/api/v1/transactions_spec.rb
```

### Test Coverage Targets

| Layer | Coverage |
|---|---|
| Models | Validations, callbacks, scopes, balance logic |
| Services | Transaction creation, currency conversion, webhook delivery |
| Requests | Full API endpoint integration tests |
| Jobs | Webhook delivery, retry logic, rate sync |

---

## Project Structure

```
core-ledger-api/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── base_controller.rb        # Auth, error handling
│   │   │       ├── accounts_controller.rb
│   │   │       ├── transactions_controller.rb
│   │   │       ├── webhook_endpoints_controller.rb
│   │   │       └── exchange_rates_controller.rb
│   │   └── dashboard_controller.rb           # Hotwire dashboard
│   ├── models/
│   │   ├── account.rb
│   │   ├── transaction.rb
│   │   ├── entry.rb
│   │   ├── webhook_endpoint.rb
│   │   ├── webhook_delivery.rb
│   │   ├── exchange_rate.rb
│   │   └── api_key.rb
│   ├── services/
│   │   ├── transaction_service.rb            # Core double-entry logic
│   │   ├── currency_service.rb               # Rate fetching + conversion
│   │   ├── webhook_service.rb                # Payload signing + delivery
│   │   ├── balance_service.rb                # Balance calculation
│   │   └── audit_service.rb                  # Change tracking
│   ├── jobs/
│   │   ├── webhook_delivery_job.rb
│   │   ├── webhook_retry_job.rb
│   │   ├── exchange_rate_sync_job.rb
│   │   └── balance_recalculation_job.rb
│   ├── serializers/
│   │   ├── account_serializer.rb
│   │   ├── transaction_serializer.rb
│   │   └── entry_serializer.rb
│   └── views/
│       └── dashboard/                        # Hotwire views + partials
├── config/
│   ├── routes.rb
│   └── initializers/
│       └── rack_attack.rb
├── db/
│   ├── migrate/
│   └── seeds.rb
├── spec/
│   ├── models/
│   ├── services/
│   ├── requests/
│   │   └── api/v1/
│   └── jobs/
└── README.md
```

---

## License

MIT

---

<p align="center">
  Built as a portfolio project demonstrating production-grade Rails financial infrastructure.
</p>
]]>