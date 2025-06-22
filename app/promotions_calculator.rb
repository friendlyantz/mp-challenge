# frozen_string_literal: true

class PromotionsCalculator
  def self.call(cart)
    original_total = cart.totals
    best_total = original_total
    best_message = nil

    cart.promotions.each do |promotion|
      discounted_total, message = promotion.apply(cart)

      if discounted_total < best_total
        best_total = discounted_total
        best_message = message
      end
    end

    [best_total, best_message]
  end
end
