class Promotions::PercentageOffPromotion
  attr_reader :name, :description, :threshold_amount, :percentage
  def initialize(name:, description:, threshold:, percentage:)
    @name = name
    @description = description
    @threshold_amount = threshold
    @percentage = percentage
  end

  def apply(cart)
    total = cart.totals
    threshold_in_cart_currency = Money.from_amount(@threshold_amount, cart.cart_currency)

    if total >= threshold_in_cart_currency
      discount_factor = (100 - @percentage) / 100.0
      [total * discount_factor, @description]
    else
      [total, nil]
    end
  end
end
