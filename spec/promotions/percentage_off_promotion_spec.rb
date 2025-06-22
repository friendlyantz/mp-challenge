require "spec_helper"

RSpec.describe Promotions::PercentageOffPromotion do
  let(:promotion) do
    described_class.new(
      name: "Summer Sale",
      description: "10% off orders over $50",
      threshold: 50,
      percentage: 10
    )
  end

  let(:product1) { Models::Product.new(uuid: "1", name: "Product Name A", price: 30, currency: "AUD") }
  let(:product2) { Models::Product.new(uuid: "2", name: "Product Name B", price: 25, currency: "AUD") }

  describe "#initialize" do
    it "stores the promotion attributes correctly" do
      expect(promotion.name).to eq("Summer Sale")
      expect(promotion.description).to eq("10% off orders over $50")
      expect(promotion.threshold_amount).to eq(50)
      expect(promotion.percentage).to eq(10)
    end
  end

  describe "#apply" do
    context "when cart total meets the threshold in same currency" do
      let(:cart) { ShoppingCart.new("AUD") }

      before do
        cart.add_product(product1)
        cart.add_product(product2)
      end

      it "applies the discount and returns the description" do
        discounted_total, message = promotion.apply(cart)

        expect(discounted_total).to eq(Money.from_amount(49.5, "AUD"))
        expect(message).to eq("10% off orders over $50")
      end
    end

    context "when cart total does not meet the threshold" do
      let(:cart) { ShoppingCart.new("AUD") }

      before do
        cart.add_product(product1)
      end

      it "returns the original total and no message" do
        discounted_total, message = promotion.apply(cart)

        expect(discounted_total).to eq(Money.from_amount(30, "AUD"))
        expect(message).to be_nil
      end
    end

    context "when cart currency differs from promotion threshold currency" do
      let(:cart) { ShoppingCart.new("USD") }
      let(:product_usd) { Models::Product.new(uuid: "3", name: "Product Name C", price: 40, currency: "USD") }

      before do
        cart.add_product(product_usd)
      end

      it "compares threshold in cart's currency and does not apply discount" do
        discounted_total, message = promotion.apply(cart)

        expect(discounted_total).to eq(Money.from_amount(40, "USD"))
        expect(message).to be_nil
      end
    end

    context "when cart currency differs and meets threshold" do
      let(:cart) { ShoppingCart.new("USD") }
      let(:product_usd) { Models::Product.new(uuid: "4", name: "Product Name D", price: 60, currency: "USD") }

      before do
        cart.add_product(product_usd)
      end

      it "applies discount when threshold is met in cart's currency" do
        discounted_total, message = promotion.apply(cart)

        expect(discounted_total).to eq(Money.from_amount(54, "USD"))
        expect(message).to eq("10% off orders over $50")
      end
    end

    context "with different percentage discounts" do
      let(:big_discount_promotion) do
        described_class.new(
          name: "Black Friday",
          description: "50% off orders over $100",
          threshold: 100,
          percentage: 50
        )
      end

      let(:cart) { ShoppingCart.new("AUD") }
      let(:expensive_product) { Models::Product.new(uuid: "5", name: "Expensive Product Name", price: 120, currency: "AUD") }

      before do
        cart.add_product(expensive_product)
      end

      it "applies the correct percentage discount" do
        discounted_total, message = big_discount_promotion.apply(cart)

        expect(discounted_total).to eq(Money.from_amount(60, "AUD"))
        expect(message).to eq("50% off orders over $100")
      end
    end

    context "with empty cart" do
      let(:cart) { ShoppingCart.new("AUD") }

      it "returns zero total and no discount" do
        discounted_total, message = promotion.apply(cart)

        expect(discounted_total).to eq(Money.from_amount(0, "AUD"))
        expect(message).to be_nil
      end
    end
  end
end
