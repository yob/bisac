$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'rbook/bisac'
include RBook

context "A new bisac purchase order object" do

  setup do
    @valid_file = File.dirname(__FILE__) + "/data/bisac_po.txt"
    @invalid_file_no_header = File.dirname(__FILE__) + "/data/bisac_po_no_header.txt"
    @invalid_file_no_footer = File.dirname(__FILE__) + "/data/bisac_po_no_footer.txt"
    @invalid_file_onix = File.dirname(__FILE__) + "/data/single_product.xml"
  end

  specify "Should load a valid BISAC PO file from disk correctly" do
    msg = RBook::Bisac::PO.load_from_file(@valid_file)
    msg.should be_a_kind_of(RBook::Bisac::PO)
    msg.items.size.should eql(36)

    msg.source_san.should eql("9013725")
    msg.source_suffix.should eql("")
    msg.source_name.should eql("Rainbow Book")
    msg.date.should eql("061112")
    msg.filename.should eql("INTERNET.BSC")
    msg.format_version.should eql("F03")
    msg.destination_san.should eql("9021000")
    msg.destination_suffix.should eql("")
    msg.po_number.should eql("14976")
    msg.cancellation_date.should eql("000000")
    msg.backorder.should be_true
    msg.do_not_exceed_action.should eql("")
    msg.do_not_exceed_amount.should eql("0000000")
    msg.invoice_copies.should eql("01")
    msg.special_instructions.should be_false
    msg.do_not_ship_before.should eql("000000")
  end

  specify "Should load a valid BISAC PO file from a string correctly" do
    msg = RBook::Bisac::PO.load_from_string(File.read(@valid_file))
    msg.should be_a_kind_of(RBook::Bisac::PO)
    msg.items.size.should eql(36)

    msg.source_san.should eql("9013725")
    msg.source_suffix.should eql("")
    msg.source_name.should eql("Rainbow Book")
    msg.date.should eql("061112")
    msg.filename.should eql("INTERNET.BSC")
    msg.format_version.should eql("F03")
    msg.destination_san.should eql("9021000")
    msg.destination_suffix.should eql("")
    msg.po_number.should eql("14976")
    msg.cancellation_date.should eql("000000")
    msg.backorder.should be_true
    msg.do_not_exceed_action.should eql("")
    msg.do_not_exceed_amount.should eql("0000000")
    msg.invoice_copies.should eql("01")
    msg.special_instructions.should be_false
    msg.do_not_ship_before.should eql("000000")
  end

  specify "Should raise an appropriate exception when an invalid file is loaded" do
    lambda { msg = RBook::Bisac::PO.load_from_file(@invalid_file_no_header) }.should raise_error(RBook::InvalidFileError)
    lambda { msg = RBook::Bisac::PO.load_from_file(@invalid_file_no_footer) }.should raise_error(RBook::InvalidFileError)
    lambda { msg = RBook::Bisac::PO.load_from_file(@invalid_file_onix) }.should raise_error(RBook::InvalidFileError)
  end
end
