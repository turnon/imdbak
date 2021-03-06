require "imdbak/tsv"

module Imdbak
  module Title
    NULL = "\\N"
    COMMA = ","

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

    class Ratings
      # tconst  averageRating   numVotes
      include Tsv

      POINT = '.'
      EMPTY = ''

      def parse(row)
        row[1] = row[1].sub(POINT, EMPTY).to_i
        row[2] = row[2].to_i
        row
      end
    end
  end
end
