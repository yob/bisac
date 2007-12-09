require File.dirname(__FILE__) + '/po_line_item'

module RBook
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
        raise RBook::InvalidFileError, 'Invalid file' unless File.exist?(input)
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

      # creates a RBook::Bisac::PO object from a string. Input should
      # be a complete bisac file as a string
      def self.load_from_string(input)
        data = input.split("\n")
        return self.build_message(data)
      end

      private

      def self.build_message(data)
        raise RBook::InvalidFileError, 'File appears to be too short' unless data.size >= 3
        raise RBook::InvalidFileError, 'Missing header information' unless data[0][0,2].eql?("00")
        raise RBook::InvalidFileError, 'Missing footer information' unless data[-1][0,2].eql?("90")

        msg = PO.new

        data.each do |line|

          case line[0,2]
          when "00" # first header
            msg.source_san = line[7,7].strip
            msg.source_suffix = line[14,5].strip
            msg.source_name = line[19,13].strip
            msg.date = line[32,6].strip
            msg.filename = line[38,20].strip
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
            item = RBook::Bisac::POLineItem.load_from_string(line)
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
end
