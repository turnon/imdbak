require "imdbak/tsv"

module Imdbak
  module Name
    COMMA = ","

    class Basics
      # nconst	primaryName	birthYear	deathYear	primaryProfession	knownForTitles
      include Tsv

      def parse(row)
        row[4] = row[4] ? row[4].split(COMMA) : []
        row[5] = row[5] ? row[5].split(COMMA) : []
        row
      end

      def nconst_name_map
        @nconst_name_map ||= enum.each_with_object({}) do |row, hash|
          hash[row[0]] = row[1]
        end
      end
    end
  end
end
