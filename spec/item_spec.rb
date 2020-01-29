require './main.rb'

RSpec.describe Item do
  item = Item.new('GR1', 'Green tea', Money.new(311, 'GBP'))

  it "\'s code should be a string" do
    expect(item.code).to be_kind_of(String)
  end

  it "\'s name should be a string" do
    expect(item.name).to be_kind_of(String)
  end

  it "should have a Money class price" do
    expect(item.price).to be_kind_of(Money)
  end
end
