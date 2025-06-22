require "money"

class ShoppingCart
  attr_reader :products, :promotions
  attr_accessor :cart_currency

  def initialize(cart_currency = "AUD")
    @products = []
    @promotions = []
    @cart_currency = cart_currency
  end

  def add_product(product)
    @products << product
  end

  def add_promotion(promotion)
    @promotions << promotion
  end

  def to_s
    <<~OUTPUT
      ================ Shopping Cart =========
      Products in Shopping Cart:
      #{
        products
        .tally
        .map.with_index do |(product, count), index|
          "#{index + 1}. #{product.to_s(:with_price)}".ljust(50) + " x #{count}"
        end.join("\n")
      }

      #{"Discount applied: #{totals_after_discount.last}" if totals_after_discount.last}

      ______________________________________
      TOTAL: #{totals_after_discount.first.format} (#{totals_after_discount.first.currency})
      ========================================
    OUTPUT
  end

  def totals
    return Money.new(0, cart_currency) if products.empty?

    products.map(&:price).reduce(:+).exchange_to(cart_currency)
  end

  def totals_after_discount
    PromotionsCalculator.call(self)
  end
end
