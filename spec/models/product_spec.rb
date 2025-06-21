require "spec_helper"

RSpec.describe Models::Product, type: :unit do
  # Test with different types of products
  let(:aud_product) {
    described_class.new(
      uuid: 1234,
      name: "Standard Product",
      price: "19.99"
    )
  }

  let(:gbp_product) {
    described_class.new(
      uuid: 1234,
      name: "UK Tea",
      price: "9.99",
      currency: "GBP"
    )
  }

  describe "#initialize" do
    it "sets the uuid" do
      expect(aud_product.uuid).to eq(1234)
    end

    it "sets the name" do
      expect(aud_product.name).to eq("Standard Product")
    end

    it "converts string price to Money object" do
      expect(aud_product.price).to be_a(Money)
      expect(aud_product.price.currency).to eq("AUD")
      expect(aud_product.price.to_f).to eq(19.99)
    end

    context "when price is not a string" do
      it "works with numeric price" do
        product = described_class.new(
          uuid: 1234,
          name: "Numeric Price",
          price: 29.99
        )
        expect(product.price.to_f).to eq(29.99)
      end

      it "works with integer price" do
        product = described_class.new(
          uuid: 1234,
          name: "Integer Price",
          price: 30
        )
        expect(product.price.to_f).to eq(30)
      end
    end

    context "when price is invalid" do
      it "raises an error for unsupported currency" do
        expect(
         described_class.new(
           uuid: 1234,
           name: "Yarr",
           price: "19.99",
           currency: "YARR"
         ).errors[:price]
       ).to eq(["Unknown currency 'yarr'"])
      end

      it "raises an error for negative price" do
        product = described_class.new(
          uuid: 1234,
          name: "Negative Price",
          price: "-19.99"
        )
        expect(
         product.errors[:price]
       ).to eq(["Price cannot be negative"])
      end
    end
  end

  describe "#to_s" do
    it "returns a formatted string with name and price if format argument is specified" do
      expect(aud_product.to_s(:with_price)).to eq("Standard Product - $19.99 (AUD)")
      expect(gbp_product.to_s(:with_price)).to eq("UK Tea - £9.99 (GBP)")
    end

    it "retirns a name string only when format is NOT provided or invalid" do
      expect(aud_product.to_s).to eq("Standard Product")
      expect(gbp_product.to_s).to eq("UK Tea")
      expect(gbp_product.to_s(:unknown_format)).to eq("UK Tea")
    end
  end
end
