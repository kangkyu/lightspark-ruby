# frozen_string_literal: true

module Lightspark
  CURRENCY_AMOUNT_FRAGMENT = <<-'GRAPHQL'
fragment CurrencyAmountFragment on CurrencyAmount {
    __typename
    currency_amount_original_value: original_value
    currency_amount_original_unit: original_unit
    currency_amount_preferred_currency_unit: preferred_currency_unit
    currency_amount_preferred_currency_value_rounded: preferred_currency_value_rounded
    currency_amount_preferred_currency_value_approx: preferred_currency_value_approx
}
  GRAPHQL

  class CurrencyAmount
    attr_reader :original_value, :original_unit,
      :preferred_currency_unit,
      :preferred_currency_value_rounded,
      :preferred_currency_value_approx

    def self.from_json(hash)
      new(
        original_value: hash["currency_amount_original_value"],
        original_unit: hash["currency_amount_original_unit"],
        preferred_currency_unit: hash["currency_amount_preferred_currency_unit"],
        preferred_currency_value_rounded: hash["currency_amount_preferred_currency_value_rounded"],
        preferred_currency_value_approx: hash["currency_amount_preferred_currency_value_approx"]
      )
    end

    def initialize(original_value:, original_unit:,
                   preferred_currency_unit:,
                   preferred_currency_value_rounded:,
                   preferred_currency_value_approx:)
      @original_value = original_value
      @original_unit = original_unit
      @preferred_currency_unit = preferred_currency_unit
      @preferred_currency_value_rounded = preferred_currency_value_rounded
      @preferred_currency_value_approx = preferred_currency_value_approx
    end
  end
end
