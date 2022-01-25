require "imdbak/version"
require "csv"

module Imdbak
  COMMA = ','
  NULL = "\\N"
  TAB = "\t"

  module Tsv
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

  module Title
    class Basics
      # tconst	titleType	primaryTitle	originalTitle	isAdult	startYear	endYear	runtimeMinutes	genres
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

    class Principals
      # tconst	ordering	nconst	category	job	characters
      include Tsv

      ACTOR = 'actor'

      def parse(row)
        row
      end

      def title_name_map
        @title_name_map ||= enum.each_with_object(Hash.new{ |h, k| h[k] =[] }) do |row, hash|
          hash[row[0]] << row
        end
      end

      def title_actors(t)
        title_name_map[t].select{ |name| name[3] == ACTOR }
      end
    end
  end
end
