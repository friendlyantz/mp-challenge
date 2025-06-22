require "spec_helper"
require "money"

RSpec.describe ShoppingCart do
  let(:product_a) { double("Product") }
  let(:product_b) { double("Product") }

  subject(:cart) { described_class.new }

  before do
    allow(PromotionsCalculator).to receive(:call).and_return([Money.new(0, "AUD"), nil])
  end

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

  describe "#add_promotion" do
    it "adds a promotion to the promotions array" do
      promo = double("Promotion")
      expect { cart.add_promotion(promo) }.to change { cart.promotions.count }.by(1)
      expect(cart.promotions).to eq([promo])
    end
  end

  describe "#totals_after_discount" do
    let(:cart_total_before_promo) { Money.from_amount(100, "AUD") }
    before do
      allow(cart).to receive(:totals).and_return(cart_total_before_promo)
    end

    it "applies promotions to the cart total" do
      expect(PromotionsCalculator).to receive(:call)
        .with(cart)
        .and_return([Money.from_amount(50, "AUD"), "Some promotion applied"])

      expect(cart.totals_after_discount).to eq([Money.from_amount(50, "AUD"), "Some promotion applied"])
    end
  end

  describe "#cart_currency" do
    it "defaults to AUD" do
      expect(cart.cart_currency).to eq("AUD")
    end
    it "can be set to a different currency" do
      cart.cart_currency = "USD"
      expect(cart.cart_currency).to eq("USD")
    end
  end

  describe "#to_s" do
    before do
      cart.add_product(product_a)
      cart.add_product(product_b)

      allow(product_a).to receive(:to_s).with(:with_price).and_return("product details A")
      allow(product_b).to receive(:to_s).with(:with_price).and_return("product details B")

      allow(cart).to receive(:totals)
    end

    it "outputs the cart contents and total with discount" do
      allow(PromotionsCalculator).to receive(:call).and_return([Money.from_cents(3000, "AUD"), nil])
      expect(cart.to_s).to eq(
        <<~OUTPUT
          ================ Shopping Cart =========
          Products in Shopping Cart:
          1. product details A
          2. product details B



          ______________________________________
          TOTAL: $30.00 (AUD)
          ========================================
        OUTPUT
      )
    end

    context "when promotions are applied" do
      before do
        allow(cart).to receive(:totals_after_discount).and_return(
          [Money.from_amount(25, "AUD"), "10% off promotion"]
        )
      end

      it "shows the total after discount" do
        expect(cart.to_s).to eq(
          <<~OUTPUT
            ================ Shopping Cart =========
            Products in Shopping Cart:
            1. product details A
            2. product details B

            Discount applied: 10% off promotion

            ______________________________________
            TOTAL: $25.00 (AUD)
            ========================================
        OUTPUT
        )
      end
    end
  end
end
