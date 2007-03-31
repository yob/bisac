$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'rbook/bisac'
include RBook

context "A new bisac object" do

  setup do
    @valid_item1 = RBook::Bisac::Product.new("0743285689")
    @valid_item1.title = "Enemy Combatant"
    @valid_item1.author = "Begg, Moazzam"
    @valid_item1.price = "2995"
    @valid_item1.pubdate = "060101"
    @valid_item1.publisher = "Simon and Schuster"
    @valid_item1.imprint = "Free Press"
    @valid_item1.volumes = "1"
    @valid_item1.edition = "1"
    @valid_item1.binding = "PB"
    @valid_item1.volume = "1"
    @valid_item1.status = "O/O"

    @valid_item2 = RBook::Bisac::Product.new("0975240277")
    @valid_item2.title = "HTML Utopia Designing Without Tables Using CSS"
    @valid_item2.author = "Andrew, Rachel; Shafer, Dan"
    @valid_item2.price = "5995"
    @valid_item2.pubdate = "060401"
    @valid_item2.publisher = "Sitepoint"
    @valid_item2.imprint = "Sitepoint"
    @valid_item2.volumes = "1"
    @valid_item2.edition = "2"
    @valid_item2.binding = "PB"
    @valid_item2.volume = "1"
    @valid_item2.status = "ACT"
  end

  specify "Should have product lines that are exactly 259 chars long" do
    bisac = RBook::Bisac::Message.new("Rainbow","1234567","test","1")
    bisac << @valid_item1
    bisac << @valid_item2

    bisac.to_s.split("\n").each do |line|
      line.length.should_eql(259)
    end
  end

  specify "Should load a valid BISAC file from disk correctly" do
    msg = RBook::Bisac::Message.load(File.dirname(__FILE__) + "/data/valid_bisac.txt")
    msg.company.should_eql("SAND")
    msg.san.should_eql("9012982")
    msg.batch.should_eql("000001")
    msg.code.should_eql("0")
    msg.products.size.should_eql(212)

    product = msg.products[0]
    product.isbn.should_eql("0715200615")
    product.title.should_eql("GODS YOUNG CHURCH PB")
    product.author.should_eql("Barclay, W")
    product.price.should_eql("2272")
    product.publisher.should_eql("SAND")
    product.imprint.should_eql("STANP")
    product.volumes.should_eql("")
    product.volume.should_eql("000")
    product.edition.should_eql("")
    product.binding.should_eql("")

  end

end
