# frozen_string_literal: true

require "json"

require_relative "../config/money_config"

unless defined?(Zeitwerk)
  require "zeitwerk"
  loader = Zeitwerk::Loader.new
  loader.push_dir(File.join(__dir__, "..", "app"))
  loader.push_dir(File.join(__dir__, "..", "db"))
  loader.setup
end

class App
  attr_reader :output, :database, :shopping_cart, :output_format

  def initialize(input: $stdin, output: $stdout, load_path: nil, currency: "AUD", output_format: :text)
    @input = input
    @output = output
    @output_format = output_format
    default_db_path = File.join(__dir__, "..", "db", "products.json")
    @database = load_database(load_path || default_db_path)
    @shopping_cart = load_shopping_cart_with_promos(currency)
  end

  def run
    list_menu

    run_state = true
    while run_state
      case @input&.gets&.chomp
      in "1" then list_products
      in "2" then add_product_to_cart
      in "3" then view_cart
      in "4" then list_promotions
      in "exit" | "0"
        output.puts "Exiting the Marketplacer Checkout System. Goodbye!"
        run_state = false
      else
        output.puts "Invalid menu option. Please try again."
        list_menu
      end
    end
  end

  def list_menu
    output.puts <<~OUTPUT
      ================ Marketplacer Checkout System =========
      press an number to select an option:
      1. List products
      2. Add product to cart
      3. View cart and checkout
      4. View available promotions
      0. Exit. Or type 'exit' anytime to exit
      =======================================================
    OUTPUT
  end

  def add_product_to_cart
    list_products
    output.puts "Please enter the product number to add to cart:"
    select_product
    list_menu
  end

  def add_product_to_cart_by_uuid(uuid:)
    product = database.values.find { |p| p.uuid == uuid.to_i }
    if product
      shopping_cart.add_product(product)
      JSON.generate({
        message: "Product '#{product.name}' added to cart.",
        product: {
          uuid: product.uuid,
          name: product.name,
          price: product.price.to_f,
          currency: product.price.currency.to_s,
          formatted_price: product.price.format
        }
      })
    else
      JSON.generate({
        error: "Product with UUID '#{uuid}' not found."
      })
    end
  end

  def list_products
    if output_format == :json
      products_data = generate_cli_record_mappings.map do |cli_index, product|
        {
          id: cli_index,
          uuid: product.uuid,
          name: product.name,
          price: product.price.to_f,
          currency: product.price.currency.to_s,
          formatted_price: product.price.format
        }
      end
      JSON.generate({ products: products_data })
    else
      output.puts "Available Products:" + "\n"
      generate_cli_record_mappings.each do |cli_index, product|
        output.puts "#{cli_index}. #{product.to_s(:with_price)}"
      end
    end
  end

  def list_promotions
    if output_format == :json
      promotions_data = shopping_cart.promotions.map.with_index do |promo, index|
        {
          id: index + 1,
          name: promo.name,
          description: promo.description,
          percentage: promo.percentage,
          threshold: promo.threshold_amount
        }
      end
      JSON.generate({ promotions: promotions_data })
    else
      output.puts <<~OUTPUT
        Available Promotions:
        #{
          shopping_cart.promotions
          .map.with_index do |promo, index|
            "#{index + 1}. #{promo.name}: " + promo.description.to_s
          end.join("\n")
        }
      OUTPUT
      list_menu
    end
  end

  def view_cart
    if output_format == :json
      cart_data = {
        products: shopping_cart.products.tally.map do |product, count|
          {
            uuid: product.uuid,
            name: product.name,
            price: product.price.to_f,
            currency: product.price.currency.to_s,
            formatted_price: product.price.format,
            quantity: count,
            subtotal: (product.price * count).to_f,
            formatted_subtotal: (product.price * count).format
          }
        end,
        totals: {
          subtotal: shopping_cart.totals.to_f,
          formatted_subtotal: shopping_cart.totals.format,
          final_total: shopping_cart.totals_after_discount.first.to_f,
          formatted_final_total: shopping_cart.totals_after_discount.first.format,
          discount_applied: shopping_cart.totals_after_discount.last,
          currency: shopping_cart.cart_currency
        }
      }
      JSON.generate({ cart: cart_data })
    else
      output.puts shopping_cart
      list_menu
    end
  end

  private

  def select_product
    user_selection = @input&.gets&.chomp.to_i
    record_mappings = generate_cli_record_mappings

    if record_mappings.key?(user_selection)
      shopping_cart.add_product(record_mappings[user_selection])
      output.puts "Product '#{record_mappings[user_selection]}' added to cart."
    elsif user_selection == 0 || user_selection == "exit"
      exit 0
    else
      output.puts "Invalid product number. Please try again."
    end
  end

  def generate_cli_record_mappings
    cli_mappings = {}
    database
      .values
      .each_with_index do |record, index|
        cli_mappings[index + 1] = record
      end

    cli_mappings
  end

  def load_database(load_path)
    fallback_path = File.join(__dir__, "..", "db", "products.json")
    result = Services::ProductLoader.load_from_file(load_path, fallback_path)

    if output_format != :json
      result[:messages].each { |message| output.puts message }

      if result[:products].empty?
        output.puts "Warning: No valid products loaded. Application may not function properly."
      end
    end

    result[:products]
  end

  def load_shopping_cart_with_promos(currency)
    cart = ShoppingCart.new(currency)
    result = Services::PromotionLoader.load_default_promotions

    if output_format != :json
      result[:messages].each { |message| output.puts message }
    end

    result[:promotions].each { |promotion| cart.add_promotion(promotion) }

    cart
  end
end

require 'fast_mcp'

server = FastMcp::Server.new(name: 'my-ai-server', version: '1.0.0')

APP = App.new(output_format: :json)
class BikeListingTool < FastMcp::Tool
  description "List Bike Products"

  def call
    APP.list_products
  end
end
server.register_tool(BikeListingTool)

class PromotionsListingTool < FastMcp::Tool
  description "List Bike Products"


  def call
    APP.list_promotions
  end
end
server.register_tool(PromotionsListingTool)


class BikeShoppingCartTool < FastMcp::Tool
  description "View Shopping Cart"

  def call
    APP.view_cart
  end
end

server.register_tool(BikeShoppingCartTool)

class AddBikeToCartTool < FastMcp::Tool
  description "Add Bike Product to Cart"

  arguments do
    required(:uuid).filled(:integer)
  end

  def call(uuid:)
    APP.add_product_to_cart_by_uuid(uuid:)
  end
end

server.register_tool(AddBikeToCartTool)

server.start
