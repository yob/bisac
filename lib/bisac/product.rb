module Bisac

  # Class to represent a single product line in a Bisac File. See
  # Bisac::Message for basic usage instructions.
  class Product

    attr_reader :isbn, :title, :author, :price, :pubdate, :publisher
    attr_reader :imprint, :volumes, :edition, :binding, :volume, :status

    # Creates a new product object with the requested ISBN. Must be a 10 digit ISBN.
    def initialize(isbn)
      raise ArgumentError, 'isbn must 10 chars or less' if isbn.to_s.length > 10

      @isbn = isbn.to_s
      @title = ""
      @author = ""
      @price = ""
      @pubdate = ""
      @publisher = ""
      @imprint = ""
      @volumes = ""
      @edition = ""
      @binding = ""
      @volume = ""
      @status = ""
    end

    # sets the products author. Maximum of 30 chars.
    def author=(author)
      @author = author.to_s
    end

    # sets the products binding. Maximum of 2 chars.
    def binding=(binding)
      @binding = binding.to_s
    end

    # sets the products edition number. Maximum of 3 chars.
    def edition=(edition)
      @edition = edition.to_s
    end

    # takes a single line from a BISAC file and attempts to convert
    # it to a Product object
    def self.from_string(s)
      s = s.to_s
      return nil if s.length < 259
      product = self.new(s[0,10])
      product.title = s[15,30].strip
      product.author = s[46,30].strip
      product.price = s[79,7].strip if s[79,7].strip.match(/\A\d{0,7}\Z/)
      product.pubdate = s[87,6].strip if s[87,6].strip.match(/\A\d{6}\Z/)
      product.publisher = s[94,10].strip
      product.imprint = s[105,14].strip
      product.volumes = s[120,3].strip
      product.edition = s[124,2].strip
      product.binding = s[127,2].strip
      product.volume = s[130,3].strip
      product.status = s[153,3].strip
      return product
    end

    # Sets the products imprint. Maximum of 14 chars.
    def imprint=(imprint)
      @imprint = imprint.to_s
    end

    # Sets the price imprint. Maximum of 7 chars. Must by a whole 
    # number (represent price in cents).
    def price=(price)
      unless price.to_s.match(/\A\d{0,7}\Z/)
        raise ArgumentError, 'price should be a whole number with no more than 7 digits. (price in cents)'
      end
      @price = price.to_s
    end

    # Sets the products pubdate. Must be in the form YYMMDD
    def pubdate=(pubdate)
      unless pubdate.to_s.match(/\A\d{6}\Z/)
        raise ArgumentError, 'pubdate should be a date in the form YYMMDD.'
      end
      @pubdate = pubdate.to_s
    end

    # sets the products publisher. Maximum of 10 chars.
    def publisher=(publisher)
      @publisher = publisher.to_s
    end

    # sets the products status code. Maximum of 3 chars.
    def status=(status)
      @status = status.to_s
    end

    # sets the products title. Maximum of 30 chars.
    def title=(title)
      @title = title.to_s
    end

    # Returns the product as a single line ready for inserting into a BISAC file.
    # Doesn't have a \n on the end
    def to_s
      content = ""
      content << @isbn[0,10].ljust(10) # 10 digit isbn
      content << "1"
      content << "N"
      content << "N"
      content << "B"
      content << "N"
      content << @title[0,30].ljust(30)
      content << "N"
      content << @author[0,30].ljust(30)
      content << "N"
      content << "A" # author role
      content << "N"
      content << @price[0,7].rjust(7,"0") # current price
      content << "N"
      content << @pubdate[0,6].ljust(6) # published date
      content << "N"
      content << @publisher[0,10].ljust(10) # publisher
      content << "N"
      content << @imprint[0,14].ljust(14) #imprint
      content << "N"
      content << @volumes[0,3].rjust(3,"0") # volumes included in this isbn
      content << "N"
      content << @edition[0,2].rjust(2,"0") # edition
      content << "N"
      content << @binding[0,2].rjust(2,"0") # binding
      content << "N"
      content << @volume[0,3].rjust(3,"0") # volume number
      content << "N"
      content << "0000000" # new price
      content << "N"
      content << "000000" # new price effective date
      content << "N"
      content << "   " # audience type
      content << "N"
      content << @status[0,3].rjust(3) # status
      content << "N"
      content << "      " # available date. only use for status' like NYP
      content << "N"
      content << "          " # alternate isbn
      content << "N"
      content << "999999" # out of print date. only use for status == OP
      content << "N"
      content << "   " # geographic restrictions
      content << "N"
      content << "        " # library of congress catalogue number
      content << "N"
      content << "".ljust(40) # series title
      content << "N"
      content << "0" # price code for current price
      content << "N"
      content << "0" # price code for new price
      content << "N"
      content << "0000000" # freight pass through price
      content << "N"
      content << "000000" # new freight pass through price
      content << "00000" # last changed date

      return content
    end

    # sets the products volume number. Maximum of 3 chars.
    def volume=(volume)
      @volume = volume.to_s
    end

    # sets the number of volumes in the set this product belongs to. Maximum of 3 chars.
    def volumes=(volumes)
      @volumes = volumes.to_s
    end
  end
end
