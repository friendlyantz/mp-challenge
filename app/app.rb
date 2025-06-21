class App
  attr_reader :output
  def initialize(input = $stdin, output = $stdout)
    @input = input
    @output = output
  end

  def run
    list_menu

    case @input&.gets&.chomp
    when "1"
      list_products
    when "2"
      add_product_to_cart
    when "3"
      view_cart_and_checkout
    when "4"
      list_promotions
    when "0"
      output.puts "Exiting the Marketplacer Checkout System. Goodbye!"
    else
      output.puts "Invalid option. Please try again."
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
  end

  def list_products
    output.puts <<~OUTPUT
      Available Products:
      1. Jockey Wheels - Orange - $15.39
      2. Chain Ring 146mm - $65.95
      3. Carbon Brake Pads - $92.00
      4. Front Derailleur - 34.9mm - $31.22
    OUTPUT
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
end
