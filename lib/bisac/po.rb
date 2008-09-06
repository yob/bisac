module Bisac

  # Represents a single BISAC purchase order
  class PO

    attr_accessor :source_san, :source_suffix, :source_name
    attr_accessor :date, :filename, :format_version
    attr_accessor :destination_san, :destination_suffix
    attr_accessor :po_number, :cancellation_date, :backorder
    attr_accessor :do_not_exceed_action, :do_not_exceed_amount
    attr_accessor :invoice_copies, :special_instructions
    attr_accessor :do_not_ship_before
    attr_accessor :items

    # creates a new RBook::Bisac::PO object
    def initialize
      @items = []

      # default values
      @cancellation_date = "000000"
      @do_not_ship_before = "000000"
      @backorder = true
    end

    # reads a bisac text file into memory. input should be a string
    # that specifies the file path
    def self.load_from_file(input)
      $stderr.puts "WARNING: RBook::Bisac::PO.load_from_file is deprecated. It only returns the first PO in the file. use parse_file instead."
      self.parse_file(input) { |msg| return msg }
      return nil
    end

    # return all POs from a BISAC file
    def self.parse_file(input, &block)
      raise ArgumentError, 'no file provided' if input.nil?
      raise ArgumentError, 'Invalid file' unless File.file?(input)
      data = []
      File.open(input, "r") do |f|
        f.each_line do |l|
          data << l

          # yield each message found in the file. A line starting with
          # 90 is the footer to a PO
          if data.last[0,2] == "90"
            yield self.build_message(data)
            data = []
          end
        end
      end

      # if we've got to the end of the file, and haven't hit a footer line yet, the file
      # is probably malformed. Call build_message anyway, and let it detect any errors
      yield self.build_message(data) if data.size > 0
    end

    # return all POs from a BISAC string
    def self.parse_string(input, &block)
      raise ArgumentError, 'no data provided' if input.nil?
      data = []
      input.split("\n").each do |l|
        data << l

        # yield each message found in the string. A line starting with
        # 90 is the footer to a PO
        if data.last[0,2] == "90"
          yield self.build_message(data)
          data = []
        end
      end

      # if we've got to the end of the file, and haven't hit a footer line yet, the file
      # is probably malformed. Call build_message anyway, and let it detect any errors
      yield self.build_message(data) if data.size > 0
    end

    # creates a RBook::Bisac::PO object from a string. Input should
    # be a complete bisac file as a string
    def self.load_from_string(input)
      $stderr.puts "WARNING: Bisac::PO.load_from_string is deprecated. It only returns the first PO in the string. use parse_string instead."
      data = input.split("\n")
      return self.build_message(data)
    end

    def total_qty
      @items.collect { |i| i.qty }.inject { |sum, x| sum ? sum+x : x}
    end

    def to_s
      lines = []

      # file header
      line = " " * 80
      line[0,2]   = "00" # line type
      line[2,5]   = "00001"  # line counter
      line[7,7]   = pad_trunc(@source_san, 7)
      line[14,5]  = pad_trunc(@source_suffix, 5)
      line[19,13] = pad_trunc(@source_name, 13)
      line[32,6]  = pad_trunc(@date, 6)
      line[38,22] = pad_trunc(@filename, 22)
      line[60,3]  = pad_trunc(@format_version, 3)
      line[63,7]  = pad_trunc(@destination_san, 7)
      line[70,5]  = pad_trunc(@destination_suffix, 5)
      lines << line

      # po header
      lines << ""
      lines.last << "10"
      lines.last << "00002"  # line counter
      lines.last << " "
      lines.last << @po_number.to_s.ljust(11, " ")
      lines.last << " " # TODO
      lines.last << pad_trunc(@source_san, 7)
      lines.last << pad_trunc("",5) # TODO
      lines.last << pad_trunc(@destination_san, 7)
      lines.last << pad_trunc("",5) # TODO
      lines.last << pad_trunc(@date, 6)
      lines.last << pad_trunc(@cancellation_date,6)
      lines.last << yes_no(@backorder)
      lines.last << pad_trunc(@do_not_exceed_action,1)
      lines.last << pad_trunc(@do_not_exceed_amount,7)
      lines.last << pad_trunc(@invoice_copies,2)
      lines.last << yes_no(@special_instructions)
      lines.last << pad_trunc("",5) # TODO
      lines.last << pad_trunc(@do_not_ship_before,6)

      sequence = 3
      @items.each_with_index do |item, idx|
        item.line_item_number = idx + 1
        item.sequence_number  = sequence
        lines    += item.to_s.split("\n")
        sequence += 3
      end

      # PO control
      line = " " * 80
      line[0,2]   = "50"
      line[2,5]   = (lines.size + 1).to_s.rjust(5,"0")  # line counter
      line[8,12]  = @po_number.to_s.ljust(13, " ")
      line[20,5]  = "00001" # number of POs in file
      line[25,10] = @items.size.to_s.rjust(10,"0")
      line[35,10] = total_qty.to_s.rjust(10,"0")
      lines << line

      # file trailer
      line = " " * 80
      line[0,2]   = "90"
      line[2,5]   = (lines.size+1).to_s.rjust(5,"0")  # line counter
      line[7,20]  = @items.size.to_s.rjust(13,"0")
      line[20,5]  = "00001" # total '10' (PO) records
      line[25,10] = total_qty.to_s.rjust(10,"0")
      line[35,5]  = "00001" # number of '00'-'09' records
      line[40,5]  = "00001" # number of '10'-'19' records
      line[55,5]  = (@items.size * 3).to_s.rjust(5,"0") # number of '40'-'49' records
      line[60,5]  = "00000" # number of '50'-'59' records
      line[45,5]  = "00000" # number of '60'-'69' records
      lines << line

      lines.join("\n")
    end

    private

    def yes_no(bool)
      bool ? "Y" : "N"
    end

    def pad_trunc(str, len, pad = " ")
      str = str.to_s
      if str.size > len
        str[0,len]
      else
        str.ljust(len, pad)
      end
    end

    def self.build_message(data)
      raise Bisac::InvalidFileError, 'File appears to be too short' unless data.size >= 3
      raise Bisac::InvalidFileError, 'Missing header information' unless data[0][0,2].eql?("00")
      raise Bisac::InvalidFileError, 'Missing footer information' unless data[-1][0,2].eql?("90")

      msg = PO.new

      data.each do |line|

        case line[0,2]
        when "00" # first header
          msg.source_san = line[7,7].strip
          msg.source_suffix = line[14,5].strip
          msg.source_name = line[19,13].strip
          msg.date = line[32,6].strip
          msg.filename = line[38,22].strip
          msg.format_version = line[60,3].strip
          msg.destination_san = line[63,7].strip
          msg.destination_suffix = line[70,5].strip
        when "10" # second header
          msg.po_number = line[7, 12].strip
          msg.cancellation_date = line[50,6].strip
          msg.backorder = line[56,1].eql?("Y") ? true : false
          msg.do_not_exceed_action = line[57,1].strip
          msg.do_not_exceed_amount = line[58,7].strip
          msg.invoice_copies = line[65,2].strip
          msg.special_instructions = line[67,1].eql?("Y") ? true : false
          msg.do_not_ship_before = line[73,6].strip
        when "40" # line item
          # load each lineitem into the message
          item = Bisac::POLineItem.load_from_string(line)
          msg.items << item
        when "41"
          if line.length > 21
            title = line[21, line.length - 21]
            msg.items.last.title = title.strip unless title.nil?
          end
        when "42"
          if line.length > 21
            author = line[21, line.length - 21]
            msg.items.last.author = author.strip unless author.nil?
          end
        when "90" # footer
          # check the built objects match the file
        end

      end

      # return the results
      return msg
    end
  end
end
