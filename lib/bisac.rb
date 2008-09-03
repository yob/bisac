$LOAD_PATH.unshift(File.dirname(__FILE__))

# load other files from within this lib
require 'bisac/message'
require 'bisac/product'
require 'bisac/po'
require 'bisac/po_line_item'

# require rubygems
require 'rbook/isbn'

# Ruby module for reading and writing BISAC files.
# BISAC is a really bad format for electronic exchange of data - ONIX should be
# used where possible. Here be dragons.
#
# = Basic Usage
#  require 'rubygems'
#  require 'rbook/bisac'
#  include Rbook
#  msg = Bisac::Message.new('Company', '1234567', '111111', '1'))
#  item = Bisac::Product.new('0123456789')
#  item.title = "A Book"
#  item.author = "Healy, James"
#  item.price = "1995"
#  item.binding = "PB"
#  item.status = "AVL"
#  msg << item
#  puts msg.to_s
module Bisac
  class InvalidFileError < RuntimeError; end
end
