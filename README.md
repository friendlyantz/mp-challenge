
## Usage

requires Ruby 3.4.4 as per `mise.toml` and `Gemfile`

### using native Makefile

```sh
make
```

```rust
Hi friendlyantz! Welcome to mp-challenge

Getting started

make install                  install dependencies
make test                     test app

make run                      run server

make lint                     lint app
```

### using `mise`

```sh
mise run
```

```sh
Tasks
Select a task to run
❯ code     run code
  install  install dependencies
  lint     lint Code
  test     test Code
```

# Review

Code was written using TDD  and can be reviewed commit-by-commit.
I attempted to drive out logic using BDD to write e2e /top-level test first and then drive out the logic for auxilary classes and methods.

I used [JJ-VCS](https://jj-vcs.github.io/jj/latest/) instead of Git to track changes, as I wanted to try it out and see how it works. It is a simple VCS that allows you to track changes in files and directories, so don't let non-trunk commits confuse you in `git` tools as these are relevant to JJ-VCS caching and versioning only.

time constraints: 4-8 hours

lessons learned - I should have used Dry Monads and Transactions to pass the data and stick to functional style approach for handling data. For simplicity I decided just to pipe data to get MVP

I wanted to implement MCP(Model Context Protocol) Server for AI to make choices, but struggled with integration due to time constaints and coupled CLI output.

## Domain Logic & Architecture

### Core Entities

#### Product

- Has a unique `uuid` identifier
- Contains `name`, `price`, and `currency`
- Supports multiple currencies (AUD, USD, GBP)
- Price validation ensures no negative values
- Currency conversion handled automatically via Money gem

#### Shopping Cart

- Maintains a collection of products
- Supports a default currency (AUD)
- Automatically converts product prices to cart currency
- Calculates totals with and without promotions
- Displays product quantities using Ruby's `tally` method (I naively dumped cart products into a Arrau, instead of hash and realy on `tally` method to count quantities, as it is super fast C implementation)

#### Promotions

- **Percentage Off Promotion**: Applies percentage discount when cart total meets threshold
- Promotions are evaluated and the best discount is automatically selected
- Only one promotion can be applied per transaction
- Threshold amounts are compared in the cart's currency

### Business Rules & Assumptions

#### Currency Handling

- **Base Currency**: AUD (Australian Dollar)
- **Supported Currencies**: AUD, USD, GBP
- **Exchange Rates** (configurable in `config/money_config.rb`):
  - 1 USD = 1.5 AUD
  - 1 GBP = 1.5 AUD
  - Products can be priced in any supported currency
  - Cart totals are always displayed in the cart's currency

#### Product Loading

- Products are loaded from JSON files (`db/products.json`)
- **Duplicate Detection**: Products with duplicate UUIDs are skipped
- **Data Validation**: Invalid products (missing name, invalid price) are skipped
- **Graceful Degradation**: System continues to operate with partial product failures
- **Fallback Mechanism**: Falls back to default products if specified file is missing

I was thinking about using ActiveRecord or defining my own [schema](https://github.com/friendlyantz/zd-challenge/tree/master/db) and DB objects like I did for [this zendesk](https://github.com/friendlyantz/zd-challenge/blob/master/lib/models/database.rb), but I decided to keep it simple and use JSON files for product storage, as the requirements did not necessitate a full database solution.

#### Promotion Logic

- **Threshold-based**: Promotions activate when cart total meets minimum threshold
- **Best Discount Selection**: System automatically selects the promotion offering the largest discount
- **Currency Conversion**: Thresholds are converted to cart currency for comparison
- **Default Promotions**:
  - Big Spender: 20% off orders over $100 AUD
  - Medium Spender: 15% off orders over $50 AUD  
  - Small Spender: 10% off orders over $20 AUD

  promotion object /shopping cart were written in mind to add more promotions (i.e. specific to product, or specific to card/user, but I didn't have time to implement it)

#### System Behavior

- **Menu-driven Interface**: Users navigate via numbered options
- **Input Validation**: Invalid menu selections prompt for retry
- **Graceful Exit**: Users can exit via menu option or 'exit' command
- **Error Handling**: File loading errors, validation failures handled gracefully
- **Separation of Concerns**: Business logic separated from presentation logic

### Technical Assumptions

#### Data Persistence

- Products stored in JSON format
- No database required - file-based storage
- Configuration via Ruby files

#### Extensibility

- New promotion types can be added by implementing `apply(cart)` method
- New currencies supported by updating Money gem configuration
- Product sources can be extended (database, API, etc.)

#### Performance

- In-memory operations for all calculations
