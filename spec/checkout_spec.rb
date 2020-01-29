require './main.rb'

RSpec.describe Checkout do
  Money.locale_backend = :currency

  item  = Item.new('GR1', 'Green tea',    Money.new(311,  'GBP'))
  item2 = Item.new('SR1', 'Strawberries', Money.new(500,  'GBP'))
  item3 = Item.new('CF1', 'Coffee',       Money.new(1123, 'GBP'))

  it 'should give one free Green tea when you get 2 or more' do
    pricing_rules = PricingRuleList.new
    pricing_rules.add_pricing_rule(BuyAndGetFree.new item, 2)
    
    co = Checkout.new(pricing_rules)

    co.scan(item)
    co.scan(item)

    expect(co.total.format).to eq("£3.11")
  end

  it 'should drop the strawberries price to £4.50 when you buy three or more' do
    pricing_rules = PricingRuleList.new
    pricing_rules.add_pricing_rule(BuyAndGetDiscount.new item2, 3, 0.1)
    
    co = Checkout.new(pricing_rules)

    co.scan(item2)
    co.scan(item2)
    co.scan(item2)

    expect(co.total.format).to eq("£13.50")
  end

  it 'should drop the coffee price to two thirds of the original price when you buy three or more' do
    pricing_rules = PricingRuleList.new
    pricing_rules.add_pricing_rule(BuyAndGetDiscount.new item3, 3, 1.0/3)
    
    co = Checkout.new(pricing_rules)

    co.scan(item3)
    co.scan(item3)
    co.scan(item3)

    expect(co.total.format).to eq("£22.47")
  end

  it "should scan any item and add it to checkout" do
    co = Checkout.new

    co.scan(item)

    expect(co.items[item.code.to_sym][:object]).to be_kind_of(Item)
  end

  it "\'s total should be a Money class" do
    pricing_rules = PricingRuleList.new
    pricing_rules.add_pricing_rule(BuyAndGetFree.new     item,  2       )
    pricing_rules.add_pricing_rule(BuyAndGetDiscount.new item2, 3, 0.1  )
    pricing_rules.add_pricing_rule(BuyAndGetDiscount.new item3, 3, 1.0/3)

    co = Checkout.new(pricing_rules)

    expect(co.total).to be_kind_of(Money)
  end
end
