$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'bisac'

context "A new bisac purchase order line item object" do

  setup do
    @valid_row = "40000030000000019629000000000107112260670000100000000000000000  000000000101    "
    @valid_isbn13_row = "40000030000000019629000000000107112260670000100000000000000000  000000000101    9780711226067"
  end
  
  specify "Should load a line from a bisac po file correctly" do
    item = Bisac::POALineItem.load_from_string(@valid_row)
    item.should be_a_kind_of(Bisac::POALineItem)

    item.sequence_number.should eql(3)
    item.line_item_number.should eql("0000000001")
    item.isbn.should eql("9780711226067")
    item.order_qty.should eql(1)
    item.unit_price.should eql(0)
    item.nett_price.should eql(0)
    item.special_price.should eql(" ")
    item.discount.should eql(0)
    item.shippable_qty.should eql(1)
    item.status.should eql(1)
    item.warehouse_status.should eql(0)
  end

  specify "Should prefer the ISBN13 over ISBN10 when available" do
    item = Bisac::POALineItem.load_from_string(@valid_isbn13_row)
    item.should be_a_kind_of(Bisac::POALineItem)

    item.isbn.should eql("9780711226067")
  end

  specify "Should correctly convert into a string" do
    item = Bisac::POALineItem.load_from_string(@valid_isbn13_row)
    item.to_s.should eql(@valid_isbn13_row)
  end

end
