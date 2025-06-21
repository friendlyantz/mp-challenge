require "money"

Money.locale_backend = nil
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
I18n.enforce_available_locales = false

Money.default_bank.add_rate("USD", "AUD", 1.5)
Money.default_bank.add_rate("AUD", "USD", 0.6666)
Money.default_bank.add_rate("GBP", "AUD", 1.5)

class ShoppingCart
  attr_reader :products
  attr_accessor :cart_currency

  def initialize(cart_currency = "AUD")
    @products = []
    @cart_currency = cart_currency
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
      Total: #{totals.format} (#{totals.currency})
      ========================================
    OUTPUT
  end

  def totals
    return Money.new(0, cart_currency) if products.empty?

    products.map(&:price).reduce(:+).exchange_to(cart_currency)
  end
end
