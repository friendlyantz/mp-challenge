# frozen_string_literal: true

require "json"

require_relative "../config/money_config"

unless defined?(Zeitwerk)
  require "zeitwerk"
  loader = Zeitwerk::Loader.new
  loader.push_dir("app")
  loader.push_dir("db")
  loader.setup
end

class App
  attr_reader :output, :database, :shopping_cart

  def initialize(input = $stdin, output = $stdout, load_path = "db/products.json", currency = "AUD")
    @input = input
    @output = output
    @database = load_database(load_path)
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

  def list_products
    output.puts "Available Products:" + "\n"
    generate_cli_record_mappings.each do |cli_index, product|
      output.puts "#{cli_index}. #{product.to_s(:with_price)}"
    end
  end

  def list_promotions
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

  def view_cart
    output.puts shopping_cart

    list_menu
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
    result = Services::ProductLoader.load_from_file(load_path, "db/products.json")

    result[:messages].each { |message| output.puts message }

    if result[:products].empty?
      output.puts "Warning: No valid products loaded. Application may not function properly."
    end

    result[:products]
  end

  def load_shopping_cart_with_promos(currency)
    cart = ShoppingCart.new(currency)
    result = Services::PromotionLoader.load_default_promotions

    result[:messages].each { |message| output.puts message }

    result[:promotions].each { |promotion| cart.add_promotion(promotion) }

    cart
  end
end
