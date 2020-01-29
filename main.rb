require 'money'
require 'money/collection'

class Item
  attr_reader :code, :name, :price

  def initialize(code, name, price)
    @code  = code
    @name  = name
    @price = price
  end
end

class PricingRule
  attr_reader :description

  def initialize(description)
    @description = description
  end

  def apply
    # Interface
  end
end

class BuyAndGetFree < PricingRule
  def initialize(product_to_be_free, quantity_of_product)
    super "If you buy #{product_to_be_free.name} #{quantity_of_product} times, you can get one free!"

    @product_to_be_free = product_to_be_free
    @quantity_of_product = quantity_of_product
  end

  def apply(item, times_added)
    (times_added >= @quantity_of_product) && (@product_to_be_free.code == item.code) ? 1 : 0
  end
end

class BuyAndGetDiscount < PricingRule
  def initialize(product_to_set_discount, quantity_of_product, discount_rate)
    super "If you buy #{product_to_set_discount.name} #{quantity_of_product} times, you can get a great discount!"

    @product_to_set_discount = product_to_set_discount
    @quantity_of_product = quantity_of_product
    @discount_rate = discount_rate
  end

  def apply(item, times_added)
    if (times_added > 1) && (@product_to_set_discount.code == item.code)
      discount_rates = []
      times_added.times { discount_rates << @discount_rate }
      discount_rates
    else
      0
    end
  end
end

class PricingRuleList < PricingRule
  attr_reader :pricing_rules

  def initialize
    @pricing_rules = []
  end

  def add_pricing_rule(pricing_rule)
    @pricing_rules << pricing_rule
  end

  def apply(item, times_added)
    discounts = []
    @pricing_rules.each { |pricing_rule| discounts << pricing_rule.apply(item, times_added) }
    discounts
  end

  def description
    description = ''
    @pricing_rules.each { |cmd| description += cmd.description + "\n" }
    description
  end
end

class Checkout
  attr_reader :pricing_rules, :items

  def initialize(pricing_rules = nil)
    @pricing_rules = pricing_rules
    @items = {}
  end

  def scan(item)
    @items[item.code.to_sym] ?
      @items[item.code.to_sym][:quantity] += 1 :
      @items[item.code.to_sym] = {object: item, quantity: 1, discount_rates: []}
  end

  def total
    prices = []
    discount_prices = []
    set_discount_rates

    @items.each do |_, item|
      item[:quantity].times { prices << item[:object].price }

      item[:discount_rates].flatten.each do |discount_rate|
        discount_prices << Money.new(item[:object].price.amount * (discount_rate * 100), item[:object].price.currency.iso_code)
      end
    end

    Money::Collection.new(prices).sum - Money::Collection.new(discount_prices).sum
  end

  private

    def apply_pricing_rules(item)
      @pricing_rules.apply(item, @items[item.code.to_sym][:quantity])
    end

    def reset_discounts
      @items.each { |_, item| item[:discount_rates] = [] }
    end

    def set_discount_rates
      reset_discounts
      @items.each do |_, item|
        @items[item[:object].code.to_sym][:discount_rates] << apply_pricing_rules(item[:object])
      end
    end
end

def main
  Money.locale_backend = :currency

  $item  = Item.new('GR1', 'Green tea',    Money.new(311,  'GBP'))
  $item2 = Item.new('SR1', 'Strawberries', Money.new(500,  'GBP'))
  $item3 = Item.new('CF1', 'Coffee',       Money.new(1123, 'GBP'))

  $pricing_rules = PricingRuleList.new
  $pricing_rules.add_pricing_rule(BuyAndGetFree.new     $item,  2       )
  $pricing_rules.add_pricing_rule(BuyAndGetDiscount.new $item2, 3, 0.1  )
  $pricing_rules.add_pricing_rule(BuyAndGetDiscount.new $item3, 3, 1.0/3)

  $co1 = Checkout.new($pricing_rules)
  $co2 = Checkout.new($pricing_rules)
  $co3 = Checkout.new($pricing_rules)
  $co4 = Checkout.new($pricing_rules)

  # Test Data

  # 1

  $co1.scan($item)
  $co1.scan($item2)
  $co1.scan($item)
  $co1.scan($item)
  $co1.scan($item3)
  p $co1.total.format

  # 2

  $co2.scan($item)
  $co2.scan($item)
  p $co2.total.format

  # 3

  $co3.scan($item2)
  $co3.scan($item2)
  $co3.scan($item)
  $co3.scan($item2)
  p $co3.total.format

  # 4

  $co4.scan($item)
  $co4.scan($item3)
  $co4.scan($item2)
  $co4.scan($item3)
  $co4.scan($item3)
  p $co4.total.format
end
