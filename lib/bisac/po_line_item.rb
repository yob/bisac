require 'bigdecimal'

module Bisac

  # represents a single line on the purchase order. Has attributes like
  # price, qty and description
  class POLineItem
    include Bisac::Utils

    attr_accessor :sequence_number, :po_number, :line_item_number
    attr_accessor :qty, :catalogue_code, :price
    attr_accessor :author, :title
    attr_reader :isbn

    # returns a new Bisac::POLineItem object using the data passed in as a string
    # refer to the bisac spec for the expected format of the string
    def self.load_from_string(data)
      raise ArgumentError, 'data must be a string' unless data.kind_of? String
      data.strip!

      item = self.new

      item.sequence_number = data[2,5].to_i
      item.po_number = data[7,13].strip
      item.line_item_number = data[21,10].strip

      # prefer the 13 digit ISBN if it exists (it's a non-standard, Pacstream extension)
      # fallback to the ISBN10
      item.isbn = data[80,13]
      item.isbn ||= data[31,10]
      item.isbn.strip!
      item.qty = data[41,5].to_i
      item.catalogue_code = data[46,1].strip
      item.price = BigDecimal.new(data[47,6])

      return item
    end

    def isbn=(val)
      if EAN13.valid?(val)
        @isbn = val
      elsif ISBN10.valid?(val)
        @isbn = ISBN10.new(val).to_ean
      else
        @isbn = val
      end
    end

    # is the isbn for this product valid?
    def isbn?
      EAN13.valid?(@isbn)
    end

    def isbn10
      if isbn? && @isbn[0,3] == "978"
        ISBN10.complete(@isbn[3,9])
      else
        @isbn
      end
    end

    def to_s
      lines = [""]
      lines[0] << "40"
      lines[0] << @sequence_number.to_s.rjust(5,"0")
      lines[0] << " "
      lines[0] << @po_number.to_s.ljust(11," ")
      lines[0] << " " # TODO
      lines[0] << "Y" # TODO
      lines[0] << @line_item_number.to_s.rjust(10,"0")
      lines[0] << pad_trunc(isbn10, 10)
      lines[0] << @qty.to_s.rjust(5, "0")
      lines[0] << "00000000000000000000000000000" # TODO
      lines[0] << "     "

      # if we're ordering a valid ISBN, append a non-standard
      # ISBN13 to the line
      if isbn?
        lines[0] << @isbn
      end

      if @title && @title.to_s.size > 0
        lines << ""
        lines[1] << "41"
        lines[1] << (@sequence_number + 1).to_s.rjust(5,"0")
        lines[1] << " "
        lines[1] << @po_number.to_s.ljust(11," ")
        lines[1] << "    "
        lines[1] << pad_trunc(@title, 30)
      end

      if @author && @author.to_s.size > 0
        lines << ""
        lines[2] << "42"
        lines[2] << (@sequence_number + 2).to_s.rjust(5,"0")
        lines[2] << " "
        lines[2] << @po_number.to_s.ljust(11," ")
        lines[2] << "                  " # TODO
        lines[2] << pad_trunc(@author, 30)
      end

      lines.join("\n")
    end

  end
end
