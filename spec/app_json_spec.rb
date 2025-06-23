# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "json"

RSpec.describe App, "JSON output format" do
  let(:input) { StringIO.new("") }
  let(:output) { StringIO.new }
  let(:load_path) { "spec/fixtures/simple_products.json" }

  describe "when output_format is :json" do
    let(:app) { App.new(input, output, load_path, "AUD", :json) }

    it "outputs products in JSON format" do
      app.list_products

      json_output = JSON.parse(output.string)
      expect(json_output).to have_key("products")
      expect(json_output["products"]).to be_an(Array)
      expect(json_output["products"].size).to eq(2)

      first_product = json_output["products"].first
      expect(first_product).to include(
        "id" => 1,
        "name" => "Name A",
        "price" => 10.0,
        "currency" => "USD"
      )
    end

    it "outputs promotions in JSON format" do
      app.list_promotions

      json_output = JSON.parse(output.string)
      expect(json_output).to have_key("promotions")
      expect(json_output["promotions"]).to be_an(Array)
      expect(json_output["promotions"].size).to eq(3)

      first_promotion = json_output["promotions"].first
      expect(first_promotion).to include(
        "id" => 1,
        "name" => "Big Spender",
        "percentage" => 20,
        "threshold" => 100
      )
    end

    it "outputs cart in JSON format" do
      # Add a product to cart first
      app.shopping_cart.add_product(app.database.values.first)
      app.view_cart

      json_output = JSON.parse(output.string)
      expect(json_output).to have_key("cart")
      expect(json_output["cart"]).to have_key("products")
      expect(json_output["cart"]).to have_key("totals")
      expect(json_output["cart"]["totals"]).to have_key("currency")
    end

    it "suppresses loading messages in JSON mode" do
      # The output should only contain JSON, no loading messages
      app # Initialize the app
      expect(output.string).not_to include("Loaded product:")
      expect(output.string).not_to include("Loaded promotion:")
    end
  end

  describe "when output_format is :text (default)" do
    let(:app) { App.new(input, output, load_path, "AUD", :text) }

    it "outputs products in text format" do
      app.list_products

      expect(output.string).to include("Available Products:")
      expect(output.string).to include("1. Name A")
      expect(output.string).not_to include("{")
      expect(output.string).not_to include("}")
    end

    it "includes loading messages in text mode" do
      app # Initialize the app
      expect(output.string).to include("Loaded product:")
      expect(output.string).to include("Loaded promotion:")
    end
  end
end
