require "csv"

module Imdbak
  module Tsv
    TAB = "\t"

    def initialize(file_path, take: nil)
      @file_path = file_path
      @take = take
    end

    def enum
      Enumerator.new do |yielder|
        rows = CSV.foreach(@file_path, col_sep: TAB, liberal_parsing: true).lazy.drop(1)
        rows = rows.take(@take) if @take
        rows.each do |row|
          yielder << parse(row)
        end
      end
    end
  end
end
