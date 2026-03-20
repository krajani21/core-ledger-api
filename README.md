# 💰 Core Ledger API

> A production-grade, double-entry accounting ledger engine built with Ruby on Rails — similar to the financial infrastructure powering Stripe, Shopify, and WealthSimple.

[![Ruby](https://img.shields.io/badge/Ruby-3.2+-red?logo=ruby)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1+-red?logo=rubyonrails)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7+-red?logo=redis)](https://redis.io/)

---

## 📖 Overview

Core Ledger API provides the foundational financial infrastructure to record transactions, maintain account balances, handle multi-currency conversions, and notify external systems via webhooks. 

At its core, it enforces **double-entry bookkeeping**: a system where every financial movement creates balanced debit and credit entries. Books always sum to zero, ensuring complete auditability and preventing "lost money" bugs.

### Key Capabilities
- **Strict Accounting:** Transactions cannot be deleted or modified once posted. Reversals must be explicit.
- **Idempotent API:** Repeating a request with the same `idempotency_key` is completely safe.
- **Multi-Currency:** Auto-converts between currencies using live or cached exchange rates.
- **Resilient Webhooks:** External services are notified of ledger events via a system that supports exponential backoff retries.
- **Real-Time Dashboard:** A Hotwire-powered UI to monitor high-volume transactions as they happen.

---

## 🏗 System Architecture

The project is structured into distinct layers to handle high throughput and ensure data integrity.

```text
       [ External Clients ]
               │ (REST API / Bearer Token)
               ▼
      [ Rails API Layer ] ──▶ [ Service Layer ] (Business Logic / Double-Entry checks)
               │                        │
               ▼                        ▼
[ Sidekiq Background Workers ]   [ PostgreSQL DB ] (Data integrity, constraints)
               │                        │
               ▼                        ▼
      [ Redis Cache ]  ◀─────────  [ Hotwire Dashboard ] (WebSocket Streams)
```

1. **API Layer**: Handles routing, API key validation, and idempotency checks.
2. **Service Layer**: Models complex accounting behaviors (e.g., `TransactionService` validates debit/credit balances; `CurrencyService` fetches rates).
3. **Background Jobs (Sidekiq)**: Processes async operations like dispatching HTTP webhooks to other services without slowing down the API response.

---

## 🗄️ Core Data Model

The database strictly protects the ledger against invalid states (e.g., imbalanced entries) using PostgreSQL constraints and Rails validations.

### 1. `Account`
Tracks the identity, default currency, and current balance. Examples: `user_123_wallet`, `stripe_processing_fees`.

### 2. `Transaction`
Represents a single business event (e.g., "Payout to Merchant").
- **`idempotency_key`**: A unique string provided by the client to prevent double-processing.
- **`status`**: `pending`, `posted`, or `reversed`.

### 3. `Entry`
The backbone of the ledger. A `Transaction` has 2 or more corresponding `Entry` records.
- Records `account_id`, `amount`, `currency`, and `entry_type` (`debit` or `credit`).
- **Invariant Guarantee**: The sum of all debits MUST exactly equal the sum of all credits in a transaction.

### 4. `WebhookEndpoint` & `WebhookDelivery`
Stores registered third-party URLs and the history of HTTP requests (and retry attempts) sent to them.

---

## 🔄 Core Workflows

### 1. Processing a Transaction & Multi-Currency
When a client initiates a standard payment (e.g., $50 CAD from User A to User B), the API ensures both accounts are updated correctly. If User A pays with USD and User B receives CAD, the system consults the `CurrencyService` to determine the exchange rate (cached in Redis), executes the balanced debits and credits, and updates both accounts via a single atomic SQL transaction.

### 2. Webhook Dispatch and Retries
Whenever a `Transaction` becomes `posted`, a webhook dispatch event is enqueued into Redis for Sidekiq:
1. The background worker signs the JSON payload using `HMAC-SHA256`.
2. It attempts an HTTP `POST` request to the registered external system.
3. If the external system fails or times out, Sidekiq schedules a retry with **exponential backoff** (e.g., 1m, 5m, 30m, 2h).

---

## 💻 API Reference

### 1. Authentication
All endpoints require a Bearer token supplied in the headers:
```http
Authorization: Bearer cla_live_xxxxxxxx
```

### 2. Creating a Transaction
```http
POST /api/v1/transactions
Content-Type: application/json
```
```json
{
  "idempotency_key": "order_789_payment",
  "reference": "Order 789 Checkout",
  "entries": [
    {
      "account_id": 1,
      "entry_type": "debit",
      "amount": "100.00",
      "currency": "USD"
    },
    {
      "account_id": 2,
      "entry_type": "credit",
      "amount": "100.00",
      "currency": "USD"
    }
  ]
}
```

### 3. Fetching Account Details
```http
GET /api/v1/accounts/1
```
```json
{
  "id": 1,
  "name": "merchant_revenue",
  "currency": "USD",
  "balance": "450.00",
  "created_at": "2026-03-01T12:00:00Z"
}
```

---

## 🚀 Setup & Installation

**Prerequisites:**
- Ruby 3.2+
- Rails 7.1+
- PostgreSQL 15+
- Redis 7+

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/core-ledger-api.git
cd core-ledger-api

# 2. Install dependencies
bundle install

# 3. Setup the database (creates schema and demo seed data)
rails db:create db:migrate db:seed

# 4. Boot supporting infrastructure (requires a separate terminal or service)
redis-server

# 5. Start Sidekiq background workers (in a new terminal tab)
bundle exec sidekiq

# 6. Start the API & ActionCable Development Server
bin/dev
```

Once running, you can visit `http://localhost:3000/dashboard` to see the live view of the ledger.

---

## 🧪 Testing

The system is rigorously tested using `RSpec`, validating complex multi-currency accounting scenarios and background worker retry logics.

```bash
bundle exec rspec
```