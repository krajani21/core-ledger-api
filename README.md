# 💰 Core Ledger API

> A lightweight, production-grade, double-entry accounting ledger engine built with Ruby on Rails.

[![Ruby](https://img.shields.io/badge/Ruby-3.2+-red?logo=ruby)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1+-red?logo=rubyonrails)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)](https://www.postgresql.org/)

---

## 📖 Overview

Core Ledger API provides the foundational financial infrastructure to record transactions, maintain account balances, handle multi-currency conversions, and ensure data integrity. 

At its core, it enforces **double-entry bookkeeping**: a system where every financial movement creates balanced debit and credit entries. Books always sum to zero, ensuring complete auditability and preventing "lost money" bugs.

### Key Capabilities
- **Strict Accounting:** Transactions cannot be deleted or modified once posted. Reversals must be explicit.
- **Idempotent API:** Repeating a request with the same `idempotency_key` is completely safe.
- **Multi-Currency:** Auto-converts between currencies using live or exchange rates.

---

## 🏗 System Architecture

The project is structured into distinct layers to handle high throughput and ensure data integrity.

```text
       [ External Clients ]
               │ (REST API / Bearer Token)
               ▼
      [ Rails API Layer ] ──▶ [ Service Layer ] (Business Logic / Double-Entry checks)
                                        │
                                        ▼
                                [ PostgreSQL DB ] (Data integrity, constraints)
```

1. **API Layer**: Handles routing, API key validation, and idempotency checks.
2. **Service Layer**: Models complex accounting behaviors (e.g., `TransactionService` validates debit/credit balances; `CurrencyService` fetches rates).
3. **Database Layer**: PostgreSQL enforces schema constraints to prevent invalid states.

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

---

## 🔄 Core Workflows

### 1. Processing a Transaction & Multi-Currency
When a client initiates a standard payment (e.g., $50 CAD from User A to User B), the API ensures both accounts are updated correctly. If User A pays with USD and User B receives CAD, the system consults the `CurrencyService` to determine the exchange rate, executes the balanced debits and credits, and updates both accounts via a single atomic SQL transaction.

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

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/core-ledger-api.git
cd core-ledger-api

# 2. Install dependencies
bundle install

# 3. Setup the database (creates schema and demo seed data)
rails db:create db:migrate db:seed

# 4. Start the API Server
bin/rails server
```

---

## 🧪 Testing

The system is comprehensively tested using Minitest (the Rails default) to ensure complex multi-currency accounting scenarios are perfectly balanced.

```bash
bin/rails test
```