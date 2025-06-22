# frozen_string_literal: true

module Services
  class PromotionLoader
    def self.load_default_promotions
      promotions = []
      messages = []

      promotions_config = [
        {
          name: "Big Spender",
          percentage: 20,
          description: "20% off on total greater than $100",
          threshold: 100
        },
        {
          name: "Medium Spender",
          percentage: 15,
          description: "15% off on total greater than $50",
          threshold: 50
        },
        {
          name: "Small Spender",
          percentage: 10,
          description: "10% off on total greater than $20",
          threshold: 20
        }
      ]

      promotions_config.each do |config|
        promotion = Promotions::PercentageOffPromotion.new(**config)
        promotions << promotion
        messages << "Loaded promotion: #{promotion.name}"
      end

      {promotions: promotions, messages: messages}
    rescue => e
      {promotions: [], messages: ["Error loading promotions: #{e.message}"]}
    end
  end
end
