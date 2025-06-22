# frozen_string_literal: true

require "active_model"
require "active_support/core_ext/string"
require "money"

module Models
  class Product
    include ::ActiveModel::Model
    include ::ActiveModel::Validations

    attr_reader :uuid, :name, :price, :currency

    validates :uuid, presence: true
    validates :name, presence: true

    def initialize(uuid:, name:, price:, currency: "AUD")
      @uuid = uuid
      @name = name
      @price = validate_and_convert_price(price, currency)
    end

    def to_s(format = nil)
      if format == :with_price
        "#{name} - #{price.format} (#{price.currency})"
      else
        name
      end
    end

    def validate_and_convert_price(price, currency)
      m = Money.from_amount(price.to_f, currency)

      errors.add(:price, "Price cannot be negative") if m.negative?
      m
    rescue ArgumentError => e
      errors.add(:price, e.message)
      Money.new(0, "AUD")
    end
  end
end
