require "imdbak/version"
require "csv"

module Imdbak
  COMMA = ','
  NULL = "\\N"
  TAB = "\t"

  module Tsv
    def initialize(file_path)
      @file_path = file_path
    end

    def enum
      Enumerator.new do |yielder|
        rows = CSV.foreach(@file_path, col_sep: TAB, liberal_parsing: true).lazy.drop(1)
        rows.each do |row|
          yielder << parse(row)
        end
      end
    end
  end

  module Title
    class Basics
      include Tsv

      def parse(row)
        row[4] = row[4].to_i
        row[5] = row[5].to_s
        row[6] = row[6].to_s
        row[7] = (row[7] == NULL ? 0 : row[-2]).to_i
        row[8] = row[8] ? row[8].split(COMMA) : []
        row
      end
    end
  end
end
