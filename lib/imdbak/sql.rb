require "active_record"

module Imdbak
  module Sql
    class << self
      def init_db(path)
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: path)
      end
    end

    class Migration < ActiveRecord::Migration[7.0]
      def change
        create_table :titles do |t|
          t.string :tconst
          t.string :title_type
          t.string :primary_title
          t.string :original_title
          t.boolean :is_adult
          t.string :start_year
          t.string :end_year
          t.integer :runtime_minutes
          t.string :genres
        end
      end
    end

    class Title < ActiveRecord::Base
    end
  end
end
