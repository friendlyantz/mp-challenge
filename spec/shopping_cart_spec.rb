require "spec_helper"
require "money"

RSpec.describe ShoppingCart do
  let(:product_a) { double("Product") }
  let(:product_b) { double("Product") }

  subject(:cart) { described_class.new }

  describe "#initialize" do
    it "initializes with empty products and promotions arrays" do
      expect(cart.products).to be_empty
    end
  end

  describe "#add_product" do
    it "adds a product to the products array" do
      expect { cart.add_product(product_a) }.to change { cart.products.count }.by(1)
      expect(cart.products).to include(product_a)
    end
  end

  describe "#totals" do
    context "when cart is empty" do
      it "returns zero money" do
        expect(cart.totals).to eq(Money.new(0, "AUD"))
      end
    end

    context "when cart has products" do
      it "sums up product prices" do
        allow(product_a).to receive(:price).and_return(Money.from_amount(10.50, "AUD"))
        allow(product_b).to receive(:price).and_return(Money.from_amount(20.25, "AUD"))

        cart.add_product(product_a)
        cart.add_product(product_b)

        expect(cart.totals).to eq(
          Money.from_amount(30.75, "AUD")
        )
      end

      it "handles products with AUD and USD currencies at a rate USDAUD: 1.5" do
        aud_price = Money.from_amount(50, "AUD")
        usd_price = Money.from_amount(100, "USD")

        allow(product_a).to receive(:price).and_return(aud_price)
        allow(product_b).to receive(:price).and_return(usd_price)

        cart.add_product(product_a)
        cart.add_product(product_b)

        expect(cart.totals).to eq(
          Money.from_amount(200, "AUD") # Assuming 1 USD = 0.9 AUD
        )
      end
    end
  end

  describe "#to_s" do
    it "outputs the cart contents and total with discount" do
      cart.add_product(product_a)
      cart.add_product(product_b)

      expect(product_a).to receive(:to_s).with(:with_price).and_return("product details A")
      expect(product_b).to receive(:to_s).with(:with_price).and_return("product details B")

      allow(cart).to receive(:totals).and_return(Money.from_amount(30, "AUD"))

      expect(cart.to_s).to eq(
        <<~OUTPUT
          ================ Shopping Cart =========
          Products in Shopping Cart:
          1. product details A
          2. product details B
          ______________________________________
          Total: $30.00 (AUD)
          ========================================
        OUTPUT
      )
    end
  end
end
