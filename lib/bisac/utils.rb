module Bisac
  module Utils

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
  end
end
