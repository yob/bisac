$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'bisac'

context "A new bisac purchase order object" do

  before(:each) do
    @valid_file = File.dirname(__FILE__) + "/data/bisac_po.txt"
    @valid_multi_file = File.dirname(__FILE__) + "/data/bisac_multi_po.txt"
    @invalid_file_no_header = File.dirname(__FILE__) + "/data/bisac_po_no_header.txt"
    @invalid_file_no_footer = File.dirname(__FILE__) + "/data/bisac_po_no_footer.txt"
    @invalid_file_onix = File.dirname(__FILE__) + "/data/single_product.xml"
  end

  specify "Should load multiple POs from a single file correctly" do
    pos = []
    Bisac::PO.parse_file(@valid_multi_file) { |po| pos << po }
    
    pos.size.should eql(2)

    pos[0].should be_a_kind_of(Bisac::PO)
    pos[0].items.size.should eql(1)
    pos[0].source_name.should eql(".Pauline Book")
    pos[0].po_number.should eql("13349")

    pos[1].should be_a_kind_of(Bisac::PO)
    pos[1].items.size.should eql(10)
    pos[1].source_name.should eql(".Pauline Book")
    pos[1].po_number.should eql("13366")
  end

  specify "Should load a valid BISAC PO file from disk correctly" do
    Bisac::PO.parse_file(@valid_file) do |msg|
      msg.should be_a_kind_of(Bisac::PO)
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
  end

  specify "Should load a valid BISAC PO file from a string correctly" do
    Bisac::PO.parse_string(File.read(@valid_file)) do |msg|
      msg.should be_a_kind_of(Bisac::PO)
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
  end

  specify "Should raise an appropriate exception when an invalid file is loaded" do
    lambda { msg = Bisac::PO.parse_file(@invalid_file_no_header) }.should raise_error(Bisac::InvalidFileError)
    lambda { msg = Bisac::PO.parse_file(@invalid_file_no_footer) }.should raise_error(Bisac::InvalidFileError)
    lambda { msg = Bisac::PO.parse_file(@invalid_file_onix) }.should raise_error(Bisac::InvalidFileError)
  end
end
