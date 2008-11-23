$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'bisac'

context "The BISAC POA Class" do

  setup do
    @valid_file = File.dirname(__FILE__) + "/data/valid_poa.txt"
    @invalid_file_onix = File.dirname(__FILE__) + "/data/single_product.xml"
  end

  specify "Should load a valid BISAC PO file from disk correctly" do
    results = []
    Bisac::POA.parse_file(@valid_file) do |msg|
      results << msg
    end

    results.size.should eql(1)
    results[0].should be_a_kind_of(Bisac::POA)
  end

  specify "Should raise an appropriate exception when an invalid file is loaded" do
    lambda { msg = Bisac::POA.parse_file(@invalid_file_onix) }.should raise_error(Bisac::InvalidFileError)
  end
end

context "A BISAC POA object" do

  setup do
    @valid_file = File.dirname(__FILE__) + "/data/valid_poa.txt"
    @invalid_file_onix = File.dirname(__FILE__) + "/data/single_product.xml"
  end

  specify "should correctly load a POA message into the object using build_message()" do

    data = File.read(@valid_file).split("\n")
    msg = Bisac::POA.new
    msg.build_message(data)

    # check file header values
    msg.source_san.should      eql("1111111")
    msg.source_suffix.should   eql("")
    msg.source_name.should     eql("PACSTREAM")
    msg.date.should            eql("080904")
    msg.filename.should        eql("BISACPOA19629")
    msg.format_version.should  eql("001")
    msg.destination_san.should eql("2222222")
    msg.destination_suffix.should eql("")
    msg.ack_type.should eql("")

    # check poa header values
    msg.supplier_poa_number.should eql("0000000019629")
    msg.po_number.should eql("19629")
    msg.customer_san.should eql("2222222")
    msg.customer_suffix.should eql("")
    msg.supplier_san.should eql("1111111")
    msg.supplier_suffix.should eql("")
    msg.poa_date.should eql("080904")
    msg.currency.should eql("")
    msg.po_date.should eql("")
    msg.po_cancel_date.should eql("")
    msg.po_type.should eql("")

    msg.items.size.should eql(53)
  end

  specify "Should raise an appropriate exception when an invalid file is loaded" do
    lambda { msg = Bisac::POA.parse_file(@invalid_file_onix) }.should raise_error(Bisac::InvalidFileError)
  end

  specify "Should correctly convert into a string" do
    original = File.read(@valid_file).split("\n")
    Bisac::POA.parse_file(@valid_file) do |msg|
      msg.to_s.split("\n").size.should eql(57)
      msg.to_s.split("\n").each_with_index do |line, idx|
        line.strip.should eql(original[idx].strip)
      end
    end
  end
end
