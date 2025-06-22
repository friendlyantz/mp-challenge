# frozen_string_literal: true

require "stringio"
RSpec.describe App, type: "end to end" do
  let(:input) { StringIO.new(input_commands.join("\n")) }
  let(:output) { StringIO.new }
  let(:load_path) { "db/products.json" }
  let(:app) { App.new(input, output, load_path) }

  before do
    app.run
  end

  context "when discount applies" do
    let(:input_commands) { %w[2 1 2 2 3 exit] }

    it "it renders menu, allows to add a product to a cart and renders totals" do
      expect(output.string).to eq(
        <<~EXPECTATION
          Loaded product: Jockey Wheels - Orange - $15.39 (AUD)
          Loaded product: Chain Ring 146mm - $65.95 (AUD)
          Loaded product: Carbon Brake Pads - $92.00 (AUD)
          Loaded product: Front Derailleur - 34.9mm - $31.22 (AUD)
          ================ Marketplacer Checkout System =========
          press an number to select an option:
          1. List products
          2. Add product to cart
          3. View cart and checkout
          4. View available promotions
          0. Exit
          =======================================================
          Available Products:
          1. Jockey Wheels - Orange - $15.39 (AUD)
          2. Chain Ring 146mm - $65.95 (AUD)
          3. Carbon Brake Pads - $92.00 (AUD)
          4. Front Derailleur - 34.9mm - $31.22 (AUD)
          Please enter the product number to add to cart:
          Product 'Jockey Wheels - Orange' added to cart.
          Available Products:
          1. Jockey Wheels - Orange - $15.39 (AUD)
          2. Chain Ring 146mm - $65.95 (AUD)
          3. Carbon Brake Pads - $92.00 (AUD)
          4. Front Derailleur - 34.9mm - $31.22 (AUD)
          Please enter the product number to add to cart:
          Product 'Chain Ring 146mm' added to cart.
          ================ Shopping Cart =========
          Products in Shopping Cart:
          1. Jockey Wheels - Orange - $15.39 (AUD)
          2. Chain Ring 146mm - $65.95 (AUD)

          Discount applied: 15% off on total greater than $50

          ______________________________________
          TOTAL: $69.14 (AUD)
          ========================================
          Exiting the Marketplacer Checkout System. Goodbye!
        EXPECTATION
      )
    end
  end

  describe "promotions" do
    let(:input_commands) { %w[4 exit] }
    it "lists promos" do
      expect(output.string).to include(
        <<~EXPECTATION
          Available Promotions:
          1. Big Spender: 20% off on total greater than $100
          2. Medium Spender: 15% off on total greater than $50
          3. Small Spender: 10% off on total greater than $20
        EXPECTATION
      )
    end
  end

  describe "when invalid input is given" do
    let(:input_commands) { %w[invalid_menu_opntion exit] }
    it "does not crash and prompts for valid input" do
      expect(output.string).to include(
        <<~EXPECTATION
          Invalid menu option. Please try again.
        EXPECTATION
      )
    end
  end

  describe "graceful exit" do
    let(:input_commands) { %w[0 exit] }

    it "renders the exit message" do
      expect(output.string).to include(
        <<~EXPECTATION
          Exiting the Marketplacer Checkout System. Goodbye!
        EXPECTATION
      )
    end
  end

  context "when a different product list is provided with some records corrupt and doubling up, as well as specific currencies" do
    let(:input_commands) { %w[2 1 3 2 2 3 exit] }
    let(:load_path) { "spec/fixtures/simple_products.json" }

    it "lists the correct products in 'AUD'" do
      expect(output.string).to eq(
        <<~EXPECTATION
          Loaded product: Name A - $10.00 (USD)
          Loaded product: Name B - $20.00 (AUD)
          Duplicate product UUID detected: 1. Skipping.
          Invalid product record: {"uuid" => "invalid", "name" => nil, "price" => "bingo"}. Skipping.
          ================ Marketplacer Checkout System =========
          press an number to select an option:
          1. List products
          2. Add product to cart
          3. View cart and checkout
          4. View available promotions
          0. Exit
          =======================================================
          Available Products:
          1. Name A - $10.00 (USD)
          2. Name B - $20.00 (AUD)
          Please enter the product number to add to cart:
          Product 'Name A' added to cart.
          ================ Shopping Cart =========
          Products in Shopping Cart:
          1. Name A - $10.00 (USD)



          ______________________________________
          TOTAL: $15.00 (AUD)
          ========================================
          Available Products:
          1. Name A - $10.00 (USD)
          2. Name B - $20.00 (AUD)
          Please enter the product number to add to cart:
          Product 'Name B' added to cart.
          ================ Shopping Cart =========
          Products in Shopping Cart:
          1. Name A - $10.00 (USD)
          2. Name B - $20.00 (AUD)

          Discount applied: 10% off on total greater than $20

          ______________________________________
          TOTAL: $31.50 (AUD)
          ========================================
          Exiting the Marketplacer Checkout System. Goodbye!
        EXPECTATION
      )
    end
  end

  context "when invalid load path is provided" do
    let(:input_commands) { %w[1 exit] }

    let(:load_path) { "db/invalid_products.json" }

    it "loads default db" do
      expect(output.string).to include(
        <<~EXPECTATION
          Database file not found at db/invalid_products.json. Using default products.
        EXPECTATION
      )
    end
  end
end
