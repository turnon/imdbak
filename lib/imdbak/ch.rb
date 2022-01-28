require 'click_house'

module Imdbak
  module Ch
    class << self
      def conn_db
        ClickHouse.config do |config|
          # config.logger = Logger.new(STDOUT)
          config.timeout = 5
          config.open_timeout = 3
          config.url = 'http://localhost:8123'
          config.database = 'default'
        end
      end

      def migrate
        ClickHouse.connection.create_table('full_titles', if_not_exists: true, order: 'start_year', engine: 'MergeTree') do |t|
          t.String :tconst
          t.String :title_type
          t.String :primary_title
          t.String :original_title
          t.UInt8 :is_adult
          t.String :start_year
          t.String :end_year
          t.Int16 :runtime_minutes
          t.UInt8 :avg_rating
          t.UInt32 :num_votes
          t << 'genres Array(String)'
          t.Nested :actors do |n|
            n.String :nconst
            n.String :primary_name
            n.String :category
            n << 'characters Array(String)'
          end
          t.Nested :themselves do |n|
            n.String :nconst
            n.String :primary_name
            n << 'characters Array(String)'
          end
          t.Nested :writers do |n|
            n.String :nconst
            n.String :primary_name
            n.String :job
          end
          t.Nested :directors do |n|
            n.String :nconst
            n.String :primary_name
            n.String :job
          end
          t.Nested :producers do |n|
            n.String :nconst
            n.String :primary_name
            n.String :job
          end
          t.Nested :cinematographers do |n|
            n.String :nconst
            n.String :primary_name
            n.String :job
          end
          t.Nested :composers do |n|
            n.String :nconst
            n.String :primary_name
            n.String :job
          end
          t.Nested :editors do |n|
            n.String :nconst
            n.String :primary_name
            n.String :job
          end
          t.Nested :production_designers do |n|
            n.String :nconst
            n.String :primary_name
            n.String :job
          end
          t.Nested :archive_footages do |n|
            n.String :nconst
            n.String :primary_name
            n << 'characters Array(String)'
          end
          t.Nested :archive_sounds do |n|
            n.String :nconst
            n.String :primary_name
            n << 'characters Array(String)'
          end
        end
      end
    end

  end
end
