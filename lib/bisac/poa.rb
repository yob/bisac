module Bisac

  # Represents a single BISAC purchase order acknowledgement
  # 
  # = Generating
  #
  # It's currently not possible to generate a POA with this class. All it needs
  # is a to_s method though, much like Bisac::PO. Patches welcome.
  #
  # = Reading
  #
  # Each POA file can contain multiple POA's, so use pasrse_file() to iterate
  # over them all.
  #
  #   Bisac::POA.parse_file("filename.bsc") do |msg|
  #     puts msg.source_san
  #     puts msg.source_name
  #     puts msg.items.size
  #     ...
  #   end
  class POA
    include Bisac::Utils

    # file header attributes
    attr_accessor :source_san, :source_suffix, :source_name
    attr_accessor :date, :filename, :format_version
    attr_accessor :destination_san, :destination_suffix
    attr_accessor :ack_type

    # poa header attributes
    attr_accessor :supplier_poa_number, :po_number
    attr_accessor :customer_san, :customer_suffix
    attr_accessor :supplier_san, :supplier_suffix
    attr_accessor :poa_date, :currency, :po_date
    attr_accessor :po_cancel_date, :po_type
    attr_accessor :items

    # creates a new Bisac::POA object
    def initialize
      @items = []
    end

    # return all POAs from a BISAC file
    def self.parse_file(input, &block)
      raise ArgumentError, 'no file provided' if input.nil?
      raise ArgumentError, 'Invalid file' unless File.file?(input)
      self.parse_string(File.read(input)) do |msg|
        yield msg
      end
    end

    # return all POAs from a BISAC string
    def self.parse_string(input, &block)
      raise ArgumentError, 'no data provided' if input.nil?
      data = []
      input.split("\n").each do |l|
        data << l

        # yield each message found in the string. A line starting with
        # 91 is the footer to a POA
        if data.last[0,2] == "91"
          msg = Bisac::POA.new
          msg.build_message(data)
          yield msg
          data = []
        end
      end

      # if we've got to the end of the file, and haven't hit a footer line yet, the file
      # is probably malformed. Call build_message anyway, and let it detect any errors
      if data.size > 0
        msg = Bisac::POA.new
        msg.build_message(data)
        yield msg
      end
    end

    # total number of units ordered by the customer
    #
    def total_order_qty
      @items.collect { |i| i.order_qty }.inject { |sum, x| sum ? sum+x : x}
    end

    # total number of units to ship
    #
    def total_shippable_qty
      @items.collect { |i| i.shippable_qty }.inject { |sum, x| sum ? sum+x : x}
    end

    # convert this POA into a standards compliant string, ready for sending
    # to customers.
    #
    def to_s
      lines = []

      # file header
      line = " " * 80
      line[0,2]   = "02" # line type
      line[2,5]   = "00001"  # line counter
      line[7,7]   = pad_trunc(@source_san, 7)
      line[14,5]  = pad_trunc(@source_suffix, 5)
      line[19,13] = pad_trunc(@source_name, 13)
      line[32,6]  = pad_trunc(@date, 6)
      line[38,22] = pad_trunc(@filename, 22)
      line[60,3]  = pad_trunc(@format_version, 3)
      line[63,7]  = pad_trunc(@destination_san, 7)
      line[70,5]  = pad_trunc(@destination_suffix, 5)
      line[75,1]  = pad_trunc(@ack_type, 1)
      lines << line

      # po header
      line = " " * 80
      line[0,2]    = "11" # line type
      line[2,5]    = "00002"  # line counter
      line[7,13]   = pad_trunc(@supplier_poa_number, 13)
      line[20,13]  = pad_trunc(@po_number, 13)
      line[33,7]   = pad_trunc(@customer_san, 7)
      line[40,5]   = pad_trunc(@customer_suffice, 5)
      line[45,7]   = pad_trunc(@supplier_san, 7)
      line[52,5]   = pad_trunc(@supplier_suffice, 5)
      line[57,6]   = pad_trunc(@poa_date, 6)
      line[63,3]   = pad_trunc(@currency, 3)
      line[66,6]   = pad_trunc(@po_date, 6)
      line[72,6]   = pad_trunc(@po_cancel_date, 6)
      line[78,2]   = pad_trunc(@po_type, 2)
      lines << line

      @items.each_with_index do |item, idx|
        item.line_item_number = idx + 1
        item.sequence_number  = lines.size + 1
        lines << item.to_s
      end

      # POA control
      line = " " * 80
      line[0,2]   = "59"
      line[2,5]   = (lines.size + 1).to_s.rjust(5,"0")  # line counter
      line[7,13]  = pad_trunc(@supplier_poa_number, 13)
      line[20,5]  = (lines.size).to_s.rjust(5,"0") # number of lines to this point
      line[25,10] = (lines.size - 2).to_s.rjust(10,"0") # number of line items in file
      line[35,10] = total_shippable_qty.to_s.rjust(10,"0")
      lines << line

      # file trailer
      line = " " * 80
      line[0,2]   = "91"
      line[2,5]   = (lines.size+1).to_s.rjust(5,"0")  # line counter
      line[7,20]  = @items.size.to_s.rjust(13,"0")
      line[20,5]  = "00001" # total '11' (POA) records
      line[25,10] = total_shippable_qty.to_s.rjust(10,"0")
      line[35,5]  = "00001" # number of '00'-'09' records
      line[40,5]  = "00001" # number of '10'-'19' records
      line[45,5]  = "00000" # number of '20'-'29' records
      line[50,5]  = "00000" # number of '30'-'39' records
      line[55,5]  = (@items.size).to_s.rjust(5,"0") # number of '40'-'49' records
      line[60,5]  = "00001" # number of '50'-'59' records
      line[65,5]  = "00001" # number of '60'-'99' records
      lines << line

      lines.join("\n")
    end

    # Populate the current object with the message contained in data
    #
    # An array of lines making a complete, single POA message
    #
    def build_message(data)
      raise Bisac::InvalidFileError, 'File appears to be too short' unless data.size >= 3
      raise Bisac::InvalidFileError, 'Missing header information' unless data[0][0,2].eql?("02")
      raise Bisac::InvalidFileError, 'Missing footer information' unless data[-1][0,2].eql?("91")

      data.each do |line|
        # ensure each line is at least 80 chars long
        line = line.ljust(80)

        case line[0,2]
        when "02" # file header
          self.source_san = line[7,7].strip
          self.source_suffix = line[14,5].strip
          self.source_name = line[19,13].strip
          self.date = line[32,6].strip
          self.filename = line[38,22].strip
          self.format_version = line[60,3].strip
          self.destination_san = line[63,7].strip
          self.destination_suffix = line[70,5].strip
          self.ack_type = line[75,1].strip
        when "11" # poa header
          self.supplier_poa_number = line[7,13].strip
          self.po_number = line[20,13].strip
          self.customer_san = line[33,7].strip
          self.customer_suffix = line[40,5].strip
          self.supplier_san = line[45,7].strip
          self.supplier_suffix = line[52,5].strip
          self.poa_date = line[57,6].strip
          self.currency = line[63,3].strip
          self.po_date  = line[66,6].strip
          self.po_cancel_date = line[72,6].strip
          self.po_type = line[78,2].strip
        when "40" # line item
          item = Bisac::POALineItem.load_from_string(line)
          self.items << item
        when "41"
        when "42"
        when "59" # poa footer
          # check the built objects match the file
        when "91" # file footer
          # check the built objects match the file
        end

      end

      self
    end

  end
end
