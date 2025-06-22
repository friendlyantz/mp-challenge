# frozen_string_literal: true

require "money"

Money.locale_backend = nil
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
I18n.enforce_available_locales = false

Money.default_bank.add_rate("USD", "AUD", 1.5)
Money.default_bank.add_rate("AUD", "USD", 0.6666)
Money.default_bank.add_rate("GBP", "AUD", 1.5)
Money.default_bank.add_rate("AUD", "GBP", 0.6666)
Money.default_bank.add_rate("USD", "GBP", 0.8)
Money.default_bank.add_rate("GBP", "USD", 1.25)
