module Bisac

  # Represents a single BISAC product metadata file
  class Message

    attr_accessor :company, :san, :batch, :code, :products

    # creates a new bisac file in memory
    # params:
    # - company = company name (10 chars)
    # - san = company SAN number (12 chars)
    # - batch = batch name for this file (6 chars)
    # - code = 1 for new titles, 2 for updated titles (1 char)
    def initialize(company, san, batch, code)
      @company = company
      @san = san
      @batch = batch
      @code = code
      @products = []
    end

    # loads the requested BISAC file into memory.
    # returns a Message object or nil if the file is not 
    # a BISAC file
    def self.load(filename)
      msg = self.new(nil,nil,nil,nil)

      File.open(filename, "r") do |f|
        f.each_line do |l|
          if l[0,10].eql?("**HEADER**") 
            msg.company = l[16,10].strip
            msg.san = l[26,12].strip
            msg.batch = l[38,6].strip
            msg.code = l[44,1].strip
          elsif !l[0,11].eql?("**TRAILER**") 
            product = Bisac::Product.from_string(l)
            msg << product unless product.nil?
          end
        end
      end

      if msg.company.nil? || msg.san.nil? || msg.batch.nil? || msg.code.nil?
        return nil
      else
        return msg
      end
    end

    # adds a new title to the bisic file. Expects a Bisac::Product object.
    def << (item)
      unless item.class == Bisac::Product
        raise ArgumentError, 'item must be a Bisac::Product object'
      end
      @products << item
    end

    # converts this bisac file into a string
    def to_s
      # File Header
      content = "**HEADER**"
      content << Time.now.strftime("%y%m%d")
      content << @company[0,10].ljust(10)
      content << @san[0,12].ljust(12)
      content << @batch[0,6].ljust(6)
      content << @code[0,1].ljust(1)
      content << "**PUBSTAT*"
      content << "040"
      content << "".ljust(201)
      content << "\n"

      # File Content
      counter = 0
      @products.each do |item|
        content << item.to_s + "\n"
        counter = counter + 1
      end

      # File Footer
      content << "**TRAILER*"
      content << Time.now.strftime("%y%m%d")
      content << @batch[0,6].ljust(6)
      content << counter.to_s[0,6].ljust(6)
      content << "**PUBSTAT*"
      content << "".ljust(221)

      return content
    end

    # writes the content of this bisac file out to the specified file
    def write(filename)
      File.open(filename, "w") { |f| f.puts to_s }
    end
  end
end
