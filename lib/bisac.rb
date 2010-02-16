$LOAD_PATH.unshift(File.dirname(__FILE__))

# load other files from within this lib
require 'bisac/utils'
require 'bisac/message'
require 'bisac/product'
require 'bisac/po'
require 'bisac/po_line_item'
require 'bisac/poa'
require 'bisac/poa_line_item'

# require rubygems
require 'isbn10'
require 'ean13'

# Ruby module for reading and writing BISAC file formats.
module Bisac
  class InvalidFileError < RuntimeError; end
end
