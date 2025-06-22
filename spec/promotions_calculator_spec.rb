require "spec_helper"
require "money"

RSpec.describe PromotionsCalculator do
  describe ".call" do
    let(:cart) { double("ShoppingCart") }

    context "when cart is empty" do
      before do
        allow(cart).to receive(:totals).and_return(Money.new(0, "AUD"))
        allow(cart).to receive(:promotions).and_return([])
      end

      it "returns the original total and no message" do
        result = described_class.call(cart)
        expect(result).to eq([Money.new(0, "AUD"), nil])
      end
    end

    context "when cart has no promotions" do
      let(:total) { Money.from_amount(100, "AUD") }

      before do
        allow(cart).to receive(:totals).and_return(total)
        allow(cart).to receive(:promotions).and_return([])
      end

      it "returns the original total and no message" do
        result = described_class.call(cart)
        expect(result).to eq([total, nil])
      end
    end

    context "when cart has one promotion" do
      let(:total) { Money.from_amount(100, "AUD") }
      let(:discounted_total) { Money.from_amount(80, "AUD") }
      let(:promotion) { double("Promotion") }

      before do
        allow(cart).to receive(:totals).and_return(total)
        allow(cart).to receive(:promotions).and_return([promotion])
        allow(promotion).to receive(:apply).with(cart).and_return([discounted_total, "20% discount applied"])
      end

      it "applies the promotion and returns discounted total with message" do
        result = described_class.call(cart)
        expect(result).to eq([discounted_total, "20% discount applied"])
      end
    end

    context "when cart has multiple promotions" do
      let(:total) { Money.from_amount(100, "AUD") }
      let(:promotion1) { double("Promotion1") }
      let(:promotion2) { double("Promotion2") }
      let(:promotion3) { double("Promotion3") }

      context "and the first promotion gives the biggest discount" do
        before do
          allow(cart).to receive(:totals).and_return(total)
          allow(cart).to receive(:promotions).and_return([promotion1, promotion2, promotion3])

          allow(promotion1).to receive(:apply).with(cart).and_return([Money.from_amount(70, "AUD"), "30% discount"])
          allow(promotion2).to receive(:apply).with(cart).and_return([Money.from_amount(80, "AUD"), "20% discount"])
          allow(promotion3).to receive(:apply).with(cart).and_return([Money.from_amount(90, "AUD"), "10% discount"])
        end

        it "applies the promotion with biggest discount" do
          result = described_class.call(cart)
          expect(result).to eq([Money.from_amount(70, "AUD"), "30% discount"])
        end
      end

      context "and the last promotion gives the biggest discount" do
        before do
          allow(cart).to receive(:totals).and_return(total)
          allow(cart).to receive(:promotions).and_return([promotion1, promotion2, promotion3])

          allow(promotion1).to receive(:apply).with(cart).and_return([Money.from_amount(90, "AUD"), "10% discount"])
          allow(promotion2).to receive(:apply).with(cart).and_return([Money.from_amount(80, "AUD"), "20% discount"])
          allow(promotion3).to receive(:apply).with(cart).and_return([Money.from_amount(70, "AUD"), "30% discount"])
        end

        it "applies the promotion with biggest discount" do
          result = described_class.call(cart)
          expect(result).to eq([Money.from_amount(70, "AUD"), "30% discount"])
        end
      end

      context "and a promotion returns no discount message" do
        before do
          allow(cart).to receive(:totals).and_return(total)
          allow(cart).to receive(:promotions).and_return([promotion1, promotion2])

          # First promotion gives no discount (no message)
          allow(promotion1).to receive(:apply).with(cart).and_return([total, nil])

          # Second promotion gives 20% off
          allow(promotion2).to receive(:apply).with(cart).and_return([Money.from_amount(80, "AUD"), "20% discount"])
        end

        it "ignores promotions with no message" do
          result = described_class.call(cart)
          expect(result).to eq([Money.from_amount(80, "AUD"), "20% discount"])
        end
      end

      context "and all promotions have the same discount amount" do
        before do
          allow(cart).to receive(:totals).and_return(total)
          allow(cart).to receive(:promotions).and_return([promotion1, promotion2])

          # Both promotions give 20% off but with different messages
          allow(promotion1).to receive(:apply).with(cart).and_return([Money.from_amount(80, "AUD"), "First 20% discount"])
          allow(promotion2).to receive(:apply).with(cart).and_return([Money.from_amount(80, "AUD"), "Second 20% discount"])
        end

        it "applies the first promotion encountered" do
          result = described_class.call(cart)
          expect(result).to eq([Money.from_amount(80, "AUD"), "First 20% discount"])
        end
      end
    end

    context "with real promotion objects" do
      let(:big_spender_promotion) do
        Class.new do
          def apply(cart)
            total = cart.totals
            if total >= Money.from_amount(100, "AUD")
              [total * 0.8, "20% off on total greater than $100"]
            else
              [total, nil]
            end
          end
        end.new
      end

      let(:medium_spender_promotion) do
        Class.new do
          def apply(cart)
            total = cart.totals
            if total >= Money.from_amount(50, "AUD")
              [total * 0.85, "15% off on total greater than $50"]
            else
              [total, nil]
            end
          end
        end.new
      end

      let(:cart) { double("ShoppingCart") }

      context "when total qualifies for big spender promotion" do
        before do
          allow(cart).to receive(:totals).and_return(Money.from_amount(120, "AUD"))
          allow(cart).to receive(:promotions).and_return([big_spender_promotion, medium_spender_promotion])
        end

        it "applies the big spender promotion" do
          result = described_class.call(cart)
          expect(result.first).to eq(Money.from_amount(96, "AUD"))
          expect(result.last).to eq("20% off on total greater than $100")
        end
      end

      context "when total qualifies only for medium spender promotion" do
        before do
          allow(cart).to receive(:totals).and_return(Money.from_amount(70, "AUD"))
          allow(cart).to receive(:promotions).and_return([big_spender_promotion, medium_spender_promotion])
        end

        it "applies the medium spender promotion" do
          result = described_class.call(cart)
          expect(result.first).to eq(Money.from_amount(59.5, "AUD"))
          expect(result.last).to eq("15% off on total greater than $50")
        end
      end
    end

    context "when promotions provide discounts without messages" do
      let(:promotion_with_message) do
        double("PromotionWithMessage").tap do |promo|
          allow(promo).to receive(:apply) do |cart|
            total = cart.totals
            [total * 0.9, "10% off"] # 10% discount with message
          end
        end
      end

      let(:promotion_without_message) do
        double("PromotionWithoutMessage").tap do |promo|
          allow(promo).to receive(:apply) do |cart|
            total = cart.totals
            [total * 0.8, nil] # 20% discount but no message
          end
        end
      end

      before do
        allow(cart).to receive(:totals).and_return(Money.from_amount(100, "AUD"))
        allow(cart).to receive(:promotions).and_return([promotion_with_message, promotion_without_message])
      end

      it "chooses the best discount even if it has no message" do
        result = described_class.call(cart)
        expect(result.first).to eq(Money.from_amount(80, "AUD"))
        expect(result.last).to be_nil
      end
    end

    context "when multiple promotions have the same discount" do
      let(:promotion_a) do
        double("PromotionA").tap do |promo|
          allow(promo).to receive(:apply) do |cart|
            total = cart.totals
            [total * 0.9, "Promotion A: 10% off"]
          end
        end
      end

      let(:promotion_b) do
        double("PromotionB").tap do |promo|
          allow(promo).to receive(:apply) do |cart|
            total = cart.totals
            [total * 0.9, "Promotion B: 10% off"]
          end
        end
      end

      before do
        allow(cart).to receive(:totals).and_return(Money.from_amount(100, "AUD"))
        allow(cart).to receive(:promotions).and_return([promotion_a, promotion_b])
      end

      it "chooses the first promotion that achieves the best discount" do
        result = described_class.call(cart)
        expect(result.first).to eq(Money.from_amount(90, "AUD"))
        expect(result.last).to eq("Promotion A: 10% off")
      end
    end

    context "when no promotions provide discounts" do
      let(:no_discount_promotion) do
        double("NoDiscountPromotion").tap do |promo|
          allow(promo).to receive(:apply) do |cart|
            total = cart.totals
            [total, nil]
          end
        end
      end

      before do
        allow(cart).to receive(:totals).and_return(Money.from_amount(100, "AUD"))
        allow(cart).to receive(:promotions).and_return([no_discount_promotion])
      end

      it "returns the original total and no message" do
        result = described_class.call(cart)
        expect(result.first).to eq(Money.from_amount(100, "AUD"))
        expect(result.last).to be_nil
      end
    end
  end
end
