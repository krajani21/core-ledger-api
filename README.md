# 💰 Core Ledger API

> A production-grade, double-entry accounting ledger engine built with Ruby on Rails — similar to the financial infrastructure powering Stripe, Shopify, and WealthSimple.

[![Ruby](https://img.shields.io/badge/Ruby-3.2+-red?logo=ruby)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1+-red?logo=rubyonrails)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7+-red?logo=redis)](https://redis.io/)

## Overview

Core Ledger API provides the foundational financial infrastructure to record transactions, maintain account balances, handle multi-currency conversions, and notify external systems via webhooks. It is designed securely around a **double-entry bookkeeping system** where every financial movement creates balanced debit/credit entries.

### Key Features
- **Double-Entry Bookkeeping:** Books always sum to zero. Immutable ledger entries ensure full auditability.
- **Multi-Currency Engine:** Handles USD, CAD, EUR, etc., with real-time exchange rates.
- **Webhook Delivery System:** Notifies external services of ledger events with HMAC-signed payloads and exponential backoff retries.
- **Real-Time Dashboard:** Live-updating UI powered by Hotwire (Turbo Streams + Stimulus) — zero page refreshes.
- **Idempotency & Concurrent Safety:** Safely retry requests via idempotency keys. Optimistic locking prevents lost updates.

## Architecture

The system is built as a RESTful JSON API backed by a robust service layer, PostgreSQL for ACID guarantees, and Redis/Sidekiq for asynchronous workflows.

```
Rails API Layer ──▶ Service Layer ──▶ PostgreSQL (ACID, Primary)
                         │
                         ▼
          Sidekiq (Webhooks, Rate Syncs) ──▶ Redis
```

## Data Model

At the core, the data model strictness enforces accounting rules:
- `Account`: Tracks identity, currency, and cached balance.
- `Transaction`: Represents a business event. Tracks `idempotency_key` to prevent duplicate processing.
- `Entry`: The individual debits and credits. Every transaction must have entries that sum to strictly `$0.00`. Immutable once created.

## API Example

The API requires an API key in the `Authorization` header.

**Create a Transaction:**
```json
POST /api/v1/transactions
Content-Type: application/json
Authorization: Bearer cla_live_xxxxxxxx

{
  "idempotency_key": "txn_abc123",
  "entries": [
    { "account_id": 1, "entry_type": "debit", "amount": "50.00", "currency": "USD" },
    { "account_id": 2, "entry_type": "credit", "amount": "50.00", "currency": "USD" }
  ]
}
```

## Resiliency & Webhooks

Webhooks are processed asynchronously via Sidekiq. If a destination is unreachable, the system automatically retries with exponential backoff. Pushing ledger updates to external systems is essential for decoupling financial state from product state.

## Setup & Installation

```bash
git clone https://github.com/yourusername/core-ledger-api.git
cd core-ledger-api
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start services
redis-server
bundle exec sidekiq
bin/dev # Starts Rails serving API + Hotwire dashboard
```

## Testing
Fully tested via RSpec, covering models (accounting invariants), edge cases (currency mismatches), requests, and background jobs.
```bash
bundle exec rspec
```