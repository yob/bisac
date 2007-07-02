$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'rbook/bisac'
include RBook

context "A new bisac purchase order line item object" do

  setup do
    @valid_row = "4000003 14976       Y000000000102978513220000100000000000000000000550000000"
    @invalid_row_nil = nil
    @invalid_row_num = 23
  end

  specify "Should load a line from a bisac po file correctly" do
    item = RBook::Bisac::POLineItem.load_from_string(@valid_row)
    item.should be_a_kind_of(RBook::Bisac::POLineItem)

    item.sequence_number.should eql(3)
    item.po_number.should eql("14976")
    item.line_item_number.should eql("0000000001")
    item.isbn.should eql("0297851322")
    item.qty.should eql(1)
    item.catalogue_code.should eql("0")
    item.price.should eql(0)
  end

  specify "Should raise an appropriate exception when an invalid file is loaded" do
    lambda { item = RBook::Bisac::POLineItem.load_from_string(@invalid_row_nil) }.should raise_error(RBook::InvalidArgumentError)
    lambda { item = RBook::Bisac::POLineItem.load_from_string(@invalid_row_num) }.should raise_error(RBook::InvalidArgumentError)
  end
end
