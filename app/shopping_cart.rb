require "money"

Money.locale_backend = nil
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
I18n.enforce_available_locales = false
Money.default_currency = "AUD"

class ShoppingCart
  attr_reader :products

  def initialize
    @products = []
  end

  def add_product(product)
    @products << product
  end

  def to_s
    <<~OUTPUT
      ================ Shopping Cart =========
      Products in Shopping Cart:
      #{
        products.map.with_index do |product, index|
          "#{index + 1}. #{product.to_s(:with_price)}"
        end.join("\n")
      }
      ______________________________________
      Total: #{totals.format}
      ========================================
    OUTPUT
  end

  def totals
    return Money.new(0, "AUD") if products.empty?

    products.map(&:price).reduce(:+)
  end
end
