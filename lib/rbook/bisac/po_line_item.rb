require 'bigdecimal'
#require 'rbook/errors'

module RBook
  module Bisac

    # represents a single line on the purchase order. Has attributes like
    # price, qty and description
    class POLineItem

      attr_accessor :sequence_number, :po_number, :line_item_number
      attr_accessor :isbn, :qty, :catalogue_code, :price 
      attr_accessor :author, :title

      # returns a new RBook::Bisac::POLineItem object using the data passed in as a string
      # refer to the bisac spec for the expected format of the string
      def self.load_from_string(data)
        raise RBook::InvalidArgumentError, 'data must be a string' unless data.kind_of? String

        item = self.new

        item.sequence_number = data[2,5].to_i
        item.po_number = data[7,13].strip
        item.line_item_number = data[21,10].strip
        item.isbn = data[31,10].strip
        item.qty = data[41,5].to_i
        item.catalogue_code = data[46,1].strip
        item.price = BigDecimal.new(data[47,6])

        return item
      end

    end
  end

end
