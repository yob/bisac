$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'bisac'

context "A new bisac purchase order line item object" do

  setup do
    @valid_row = "4000003 14976       Y000000000102978513220000100000000000000000000550000000"
    @valid_row_two = "4000033 13424       Y000000001107538214940000200000000000000000000400000000      \n"
    @valid_isbn13_row = "4000003 14627       Y000000000103855198500000600000000000000000000400000000     9780385519854"
    @invalid_row_nil = nil
    @invalid_row_num = 23
  end
  
  specify "Should load a line from a bisac po file correctly" do
    item = Bisac::POLineItem.load_from_string(@valid_row)
    item.should be_a_kind_of(Bisac::POLineItem)

    item.sequence_number.should eql(3)
    item.po_number.should eql("14976")
    item.line_item_number.should eql("0000000001")
    item.isbn.should eql("0297851322")
    item.qty.should eql(1)
    item.catalogue_code.should eql("0")
    item.price.should eql(0)
  end

  specify "Should load a line from a bisac po file correctly, even if they they have whitepsace padding" do
    item = Bisac::POLineItem.load_from_string(@valid_row_two)
    item.should be_a_kind_of(Bisac::POLineItem)

    item.sequence_number.should eql(33)
    item.po_number.should eql("13424")
    item.line_item_number.should eql("0000000011")
    item.isbn.should eql("0753821494")
    item.qty.should eql(2)
    item.catalogue_code.should eql("0")
    item.price.should eql(0)
  end

  specify "Should prefer the ISBN13 over ISBN10 when available" do
    item = Bisac::POLineItem.load_from_string(@valid_isbn13_row)
    item.should be_a_kind_of(Bisac::POLineItem)

    item.isbn.should eql("9780385519854")
  end

  specify "Should raise an appropriate exception when an invalid file is loaded" do
    lambda { Bisac::POLineItem.load_from_string(@invalid_row_nil) }.should raise_error(ArgumentError)
    lambda { Bisac::POLineItem.load_from_string(@invalid_row_num) }.should raise_error(ArgumentError)
  end
end
