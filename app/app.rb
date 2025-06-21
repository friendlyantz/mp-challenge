# frozen_string_literal: true

require "json"

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
    @shopping_cart = ShoppingCart.new(currency)
  end

  def run
    list_menu

    run_state = true
    while run_state
      case @input&.gets&.chomp
      in "1" then list_products
      in "2" then add_product_to_cart
      in "3" then view_cart_and_checkout
      in "4" then list_promotions
      in "exit" | "0"
        output.puts "Exiting the Marketplacer Checkout System. Goodbye!"
        run_state = false
      else
        output.puts "Invalid menu option. Please try again."
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
      0. Exit
      =======================================================
    OUTPUT
  end

  def add_product_to_cart
    list_products
    output.puts "Please enter the product number to add to cart:"
    select_product
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
      1. Big Spender: 20% off on total greater than $100
      2. Medium Spender: 15% off on total greater than $50
      3. Small Spender: 10% off on total greater than $20
    OUTPUT
  end

  def view_cart_and_checkout
    output.puts shopping_cart
  end

  private

  def select_product
    user_selection = @input&.gets&.chomp.to_i
    record_mappings = generate_cli_record_mappings

    if record_mappings.key?(user_selection)
      shopping_cart.add_product(record_mappings[user_selection])
      output.puts "Product '#{record_mappings[user_selection]}' added to cart."
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
    if File.exist?(load_path)
      initialize_index_and_models(JSON.parse(File.read(load_path)))
    else
      output.puts "Database file not found at #{load_path}. Using default products."
      initialize_index_and_models(JSON.parse(File.read("db/products.json")))
    end
  end

  def initialize_index_and_models(records)
    index = {}
    records.map do |record|
      currency = if record["currency"].nil?
        "AUD"
      else
        record["currency"]
      end
      m = Models::Product.new(
        uuid: record["uuid"],
        name: record["name"],
        price: record["price"],
        currency: currency
      )
      if m.valid?
        if index.key?(m.uuid)
          output.puts "Duplicate product UUID detected: #{m.uuid}. Skipping."
          next
        end
        output.puts "Loaded product: #{m.name} - #{m.price.format} (#{m.price.currency})"
        index[m.uuid] = m

      else
        output.puts "Invalid product record: #{record}. Skipping."
        next
      end
    end
    index
  end
end
