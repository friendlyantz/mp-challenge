# MCP

here is Claude desctop output of the MCP server

in your claude desktop you need to set up your config to point to the server

```json
{
  "mcpServers": {
    "mp-challenge": {
      "command": "/Users/friendlyantz/.local/share/mise/installs/ruby/3.4.4/bin/ruby",
      "args": [
        "/Users/friendlyantz/code/personal/mp-challenge/app/app.rb"
      ]
    }
  }
}
```

list products

```ruby
Edit
I'll help you list the available products. Let me check what's available for you.

M

BikeListingTool

Here are the available bike products:

Jockey Wheels - Orange - $15.39 AUD (UUID: 1411)
Chain Ring 146mm - $65.95 AUD (UUID: 23881)
Carbon Brake Pads - $92.00 AUD (USD: 13008)
Front Derailleur - 34.9mm - $31.22 AUD (UUID: 9101)
Would you like to add any of these items to your cart or need more information about any specific product?
```

add jockey wheels

```ruby
I'll add the Jockey Wheels - Orange to your cart.

M

AddBikeToCartTool

Great! I've successfully added the Jockey Wheels - Orange ($15.39 AUD) to your cart.

Would you like to add any other products to your cart or view your current cart?

```

view cart

```ruby

Edit

M

BikeShoppingCartTool

Here's your current cart:

Items in Cart:

Jockey Wheels - Orange (Quantity: 1) - $15.39 AUD
Cart Summary:

Subtotal: $15.39 AUD
Final Total: $15.39 AUD
You have 1 item in your cart. Would you like to add more products or need anything else?

```

add another jockey wheel

```ruby

Edit
I'll add another Jockey Wheels - Orange to your cart.

M

AddBikeToCartTool

Perfect! I've added another Jockey Wheels - Orange ($15.39 AUD) to your cart. You now have 2 of these items in your cart.

Would you like me to show you your updated cart or add any other products?
```

what is in the cart

```ruby

Edit

M

BikeShoppingCartTool

Here's what's currently in your cart:

Items in Cart:

Jockey Wheels - Orange (Quantity: 2) - $30.78 AUD
Cart Summary:

Subtotal: $30.78 AUD
Discount Applied: 10% off on total greater than $20
Final Total: $27.70 AUD
Great news! You've qualified for a 10% discount since your total is over $20, saving you $3.08 on your order.

Would you like to add any other items or need help with anything else?

```

add Carbon Brake Pads

```ruby
I'll add the Carbon Brake Pads to your cart.

AddBikeToCartTool

Excellent! I've added the Carbon Brake Pads ($92.00 AUD) to your cart.

Your cart now contains:

2x Jockey Wheels - Orange
1x Carbon Brake Pads
Would you like me to show you your updated cart total or add any other products?

```

whats in the cart now

```ruby

BikeShoppingCartTool

Here's what's currently in your cart:

Items in Cart:

Jockey Wheels - Orange (Quantity: 2) - $30.78 AUD
Carbon Brake Pads (Quantity: 1) - $92.00 AUD
Cart Summary:

Subtotal: $122.78 AUD
Discount Applied: 20% off on total greater than $100
Final Total: $98.22 AUD
Fantastic! You've now qualified for an even better discount - 20% off since your total is over $100, saving you $24.56 on your order.

Would you like to add any other items or need help with anything else?
```

---

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
