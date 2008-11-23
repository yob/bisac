require 'bigdecimal'

module Bisac

  # represents a single line on the purchase order ack
  #
  class POALineItem
    include Bisac::Utils

    attr_accessor :sequence_number, :supplier_poa_number
    attr_accessor :line_item_number, :order_qty, :unit_price, :nett_price
    attr_accessor :list_nett_indicator, :special_price, :discount
    attr_accessor :shippable_qty, :status, :warehouse_status
    attr_reader :isbn

    # returns a new Bisac::POLineItem object using the data passed in as a string
    # refer to the bisac spec for the expected format of the string
    def self.load_from_string(data)
      data = data.to_s.ljust(93)
      raise ArgumentError, "POA Line Items must start with '40'" unless data[0,2] == "40"

      item = POALineItem.new

      item.sequence_number = data[2,5].to_i
      item.supplier_poa_number = data[7,13].strip
      item.line_item_number = data[20,10].strip

      # prefer the 13 digit ISBN if it exists (it's a non-standard, Pacstream extension)
      # fallback to the ISBN10
      item.isbn = data[80,13].strip
      item.isbn = data[30,10].strip if item.isbn.nil?
      item.order_qty = data[40,5].to_i
      item.unit_price = BigDecimal.new(data[45,8]) / 100
      item.nett_price = BigDecimal.new(data[53,9]) / 100
      item.list_nett_indicator = data[62,1]
      item.special_price = data[63,1]
      item.discount = BigDecimal.new(data[63,1]) / 100
      item.shippable_qty = data[69,5].to_i
      item.status = data[74,2].to_i
      item.warehouse_status = data[76,2].to_i

      return item
    end

    def isbn=(val)
      if val == ""
        @isbn = nil
      elsif RBook::ISBN.valid_isbn10?(val)
        @isbn = RBook::ISBN.convert_to_isbn13(val)
      else
        @isbn = val
      end
    end

    # is the isbn for this product valid?
    def isbn?
      RBook::ISBN.valid_isbn13?(@isbn || "")
    end

    def isbn10
      if isbn?
        RBook::ISBN.convert_to_isbn10(@isbn)
      else
        @isbn
      end
    end

    def to_s
      line = " " * 93
      line[0,2]   = "40" # line type
      line[2,5]   = @sequence_number.to_s.rjust(5,"0") # line counter
      line[7,13]  = pad_trunc(@supplier_poa_number, 13)
      line[20,10] = rpad_trunc(@line_item_number, 10, "0")
      line[30,10] = pad_trunc(isbn10, 10)
      line[40,5]  = rpad_trunc(@order_qty, 5, "0")
      line[45,8]  = rpad_trunc(@unit_price.to_i, 8, "0")
      line[53,9]  = rpad_trunc(@nett_price.to_i, 9, "0")
      line[62,1]  = pad_trunc(@list_nett_indicator, 1)
      line[63,1]  = rpad_trunc(@special_price, 1, "0")
      line[64,5]  = rpad_trunc(@discount.to_i, 5, "0")
      line[69,5]  = rpad_trunc(@shippable_qty, 5, "0")
      line[74,2]  = rpad_trunc(@status, 2, "0")
      line[80,13] = pad_trunc(isbn, 13)
      line
    end

    def status_text
      case self.status
      when 1  then "Accepted: Title Shipped As Ordered"
      when 2  then "Accepted: Substitute Title Shipped As Ordered"
      when 3  then "Cancelled: Future Publication"
      when 4  then "Cancelled: Future Publication" # date available
      when 5  then "Backordered: Future Publication"
      when 6  then "Cancelled: Out of Stock"
      when 7  then "Backordered: Out of Stock"
      when 8  then "Cancelled: Out of Print"
      when 9  then "Partial Ship: Cancel Rest"
      when 10 then "Partial Ship: Backorder Rest"
      when 11 then "Cancelled: HB Out of Print, PB Available"
      when 12 then "Cancelled: PB Out of Print, HB Available"
      when 13 then "Cancelled: Out of Print, Alt. Edition Available"
      when 14 then "Backordered: Subtitute Title on BO."
      when 15 then "Cancelled: No Rights"
      when 16 then "Cancelled: Not our Publication"
      when 17 then "Accepted: Free Book"
      when 18 then "Cancelled: BO Expired"
      when 19 then "Cancelled: Subscription Only"
      when 20 then "Cancelled: Not Carried"
      when 21 then "Cancelled: Not Carried"
      when 22 then "Cancelled: Import Title"
      when 23 then "Cancelled: Not Available for Wholesale"
      when 24 then "Cancelled: Kits Not Available"
      when 25 then "Cancelled: Not Available"
      when 26 then "Cancelled: New Price From Publisher"
      when 27 then "Cancelled: ISBN Not Recognised"
      when 28 then "Cancelled: Out of Print"
      when 29 then "Backordered: At Customers Request"
      else
        "UNKNOWN"
      end
    end
  end
end
