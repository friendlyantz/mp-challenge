# frozen_string_literal: true

require "json"

class App
  attr_reader :output, :database

  def initialize(input = $stdin, output = $stdout, load_path = "db/products.json")
    @input = input
    @output = output
    @database = load_database(load_path)
  end

  def run
    list_menu

    run_state = true
    while run_state
      case @input&.gets&.chomp
      in "1"
        list_products
      in "2"
        add_product_to_cart
      in "3"
        view_cart_and_checkout
      in "4"
        list_promotions
      in "exit"
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
    generate_cli_record_mappings.each do |index, record|
      output.puts "#{index}. #{record["name"]} - $#{"%.2f" % record["price"]}"
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
    output.puts <<~OUTPUT
      Products in Shopping Cart:
      1. Jockey Wheels - Orange - $15.39
      2. Chain Ring 146mm - $65.95
      3. Carbon Brake Pads - $92.00
      4. Front Derailleur - 34.9mm - $31.22

      Discount applied: 20% off on total greater than $100

      TOTAL: $163.65
    OUTPUT
  end

  private

  def select_product
    user_selection = @input&.gets&.chomp.to_i
    record_mappings = generate_cli_record_mappings

    if record_mappings.key?(user_selection)
      decorated_record = record_mappings[user_selection]["name"]
      output.puts "Product '#{decorated_record}' added to cart."
    else
      output.puts "Invalid product number. Please try again."
    end
  end

  def generate_cli_record_mappings
    mappings = {}
    database.each_with_index do |record, index|
      mappings[index + 1] = record
    end

    mappings
  end

  def load_database(load_path)
    if File.exist?(load_path)
      JSON.parse(File.read(load_path))
    else
      output.puts "Database file not found at #{load_path}. Using default products."
      JSON.parse(File.read("db/products.json"))
    end
  end
end
