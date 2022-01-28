require "active_record"

module Imdbak
  module Sql
    COMMA = ','
    BATCH_SIZE = 100000
    LOG = Logger.new(STDOUT)

    class << self
      def init_db(path)
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: path)
        # ActiveRecord::Base.logger = Logger.new(STDOUT)
      end
    end

    class CreateTitlesAndNames < ActiveRecord::Migration[7.0]
      def change
        create_table :titles, if_not_exists: true do |t|
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

        create_table :names, if_not_exists: true do |t|
          t.string :nconst
          t.string :primary_name
          t.string :birth_year
          t.string :death_year
          t.string :primary_profession
          t.string :known_for_titles
        end
      end
    end

    class CreateTitlesAndNamesIndexes < ActiveRecord::Migration[7.0]
      def change
        add_index(:titles, :tconst, if_not_exists: true, unique: true)
        add_index(:names, :nconst, if_not_exists: true, unique: true)
      end
    end

    class CreatePrincipals < ActiveRecord::Migration[7.0]
      def change
        create_table :principals, if_not_exists: true do |t|
          t.integer :title_id
          t.integer :ordering
          t.integer :name_id
          t.string :category
          t.string :job
          t.string :characters
        end
      end
    end

    class CreatePrincipalsIndexes < ActiveRecord::Migration[7.0]
      def change
        add_index(:principals, :title_id, if_not_exists: true)
        add_index(:principals, :name_id, if_not_exists: true)
      end
    end

    class CreateRatings < ActiveRecord::Migration[7.0]
      def change
        create_table :ratings, if_not_exists: true do |t|
          t.integer :title_id
          t.integer :avg_rating
          t.integer :num_votes
        end
      end
    end

    class CreateRatingsIndexes < ActiveRecord::Migration[7.0]
      def change
        add_index(:ratings, :title_id, if_not_exists: true)
      end
    end

    module Importor
      extend ActiveSupport::Concern

      module ClassMethods
        def _import(tsv_klass, file_path, individual: true, &block)
          transaction do
            LOG.debug 'start'
            tsv_klass.new(file_path).enum.each_slice(BATCH_SIZE).each_with_index do |records, idx|
              records = individual ? records.map(&block) : block.call(records)
              insert_all(records.to_a)
              LOG.debug BATCH_SIZE * idx
            end
            LOG.debug 'end'
          end
        end
      end
    end

    class Title < ActiveRecord::Base
      include Importor

      ACTOR = 'actor'
      ACTRESS = 'actress'
      ARCHIVE_FOOTAGE = 'archive_footage'
      ARCHIVE_SOUND = 'archive_sound'
      CINEMATOGRAPHER = 'cinematographer'
      COMPOSER = 'composer'
      DIRECTOR = 'director'
      EDITOR = 'editor'
      PRODUCER = 'producer'
      PRODUCTION_DESIGNER = 'production_designer'
      SELF = 'self'
      WRITER = 'writer'

      NULL = "\\N"

      has_many :principals, -> { where.not(name_id: 0).order(:ordering) }
      has_many :names, through: :principals
      has_one :rating

      class << self
        def import(file_path)
          _import(Imdbak::Title::Basics, file_path) do |t|
            {tconst: t[0], title_type: t[1], primary_title: t[2], original_title: t[3],
             is_adult: t[4] == 1, start_year: t[5], end_year: t[6], runtime_minutes: t[7], genres: t[8].join(COMMA)}
          end
        end
      end

      def to_json
        actors = []
        archive_footages = []
        archive_sounds = []
        cinematographers = []
        composers = []
        directors = []
        editors = []
        producers = []
        production_designers = []
        themselves = []
        writers = []

        principals.each do |p|
          name = p.name
          category = p.category
          case category
          when ACTOR, ACTRESS
            actors << {nconst: name.nconst, primary_name: name.primary_name, category: category, characters: p.characters == NULL ? [] : JSON.parse(p.characters)}
          when SELF
            themselves << {nconst: name.nconst, primary_name: name.primary_name, characters: p.characters == NULL ? [] : JSON.parse(p.characters)}
          when WRITER
            writers << {nconst: name.nconst, primary_name: name.primary_name, job: p.job}
          when DIRECTOR
            directors << {nconst: name.nconst, primary_name: name.primary_name, job: p.job}
          when PRODUCER
            producers << {nconst: name.nconst, primary_name: name.primary_name, job: p.job}
          when CINEMATOGRAPHER
            cinematographers << {nconst: name.nconst, primary_name: name.primary_name, job: p.job}
          when COMPOSER
            composers << {nconst: name.nconst, primary_name: name.primary_name, job: p.job}
          when EDITOR
            editors << {nconst: name.nconst, primary_name: name.primary_name, job: p.job}
          when PRODUCTION_DESIGNER
            production_designers << {nconst: name.nconst, primary_name: name.primary_name, job: p.job}
          when ARCHIVE_FOOTAGE
            archive_footages << {nconst: name.nconst, primary_name: name.primary_name, characters: p.characters == NULL ? [] : JSON.parse(p.characters)}
          when ARCHIVE_SOUND
            archive_sounds << {nconst: name.nconst, primary_name: name.primary_name, characters: p.characters == NULL ? [] : JSON.parse(p.characters)}
          end
        end

        {
          tconst: tconst,
          title_type: title_type,
          primary_title: primary_title,
          original_title: original_title,
          is_adult: is_adult ? 1 : 0,
          start_year: start_year,
          end_year: end_year,
          runtime_minutes: runtime_minutes,
          avg_rating: rating ? rating.avg_rating : 0,
          num_votes: rating ? rating.num_votes : 0,
          genres: genres.split(COMMA),
          actors: actors,
          themselves: themselves,
          writers: writers,
          directors: directors,
          producers: producers,
          cinematographers: cinematographers,
          composers: composers,
          editors: editors,
          production_designers: production_designers,
          archive_footages: archive_footages,
          archive_sounds: archive_sounds
        }
      end

      def to_ch
        json = to_json
        [:actors, :themselves, :writers, :directors, :producers, :cinematographers, :composers, :editors, :production_designers, :archive_footages, :archive_sounds].each do |attr|
          rows = json.delete(attr)
          next if rows.empty?
          rows.first.keys.each do |key|
            json["#{attr}.#{key}"] = rows.map{ |r| r[key] }
          end
        end
        json
      end
    end

    class Name < ActiveRecord::Base
      include Importor

      has_many :principals, -> { where.not(title_id: 0) }
      has_many :titles, through: :principals

      class << self
        def import(file_path)
          _import(Imdbak::Name::Basics, file_path) do |t|
            {nconst: t[0], primary_name: t[1], birth_year: t[2], death_year: t[3], primary_profession: t[4].join(COMMA), known_for_titles: t[5].join(COMMA)}
          end
        end
      end
    end

    class Principal < ActiveRecord::Base
      include Importor

      belongs_to :title, optional: true
      belongs_to :name, optional: true

      class << self
        def import(file_path)
          _import(Imdbak::Title::Principals, file_path, individual: false) do |records|
            tconsts = records.each_with_object(Set.new){ |r, set| set << r[0] }.to_a
            tconst_ids = Title.where(tconst: tconsts).pluck(:tconst, :id).to_h
            nconsts = records.each_with_object(Set.new){ |r, set| set << r[2] }.to_a
            nconst_ids = Name.where(nconst: nconsts).pluck(:nconst, :id).to_h
            records.map do |t|
              {title_id: tconst_ids[t[0]] || 0, ordering: t[1], name_id: nconst_ids[t[2]] || 0, category: t[3], job: t[4], characters: t[5]}
            end
          end
        end
      end
    end

    class Rating < ActiveRecord::Base
      include Importor

      belongs_to :title, optional: true

      class << self
        def import(file_path)
          _import(Imdbak::Title::Ratings, file_path, individual: false) do |records|
            tconst_ids = Title.where(tconst: records.map{ |r| r[0] }).pluck(:tconst, :id).to_h
            records.map { |t| {title_id: tconst_ids[t[0]] || 0, avg_rating: t[1], num_votes: t[2]} }
          end
        end
      end
    end
  end
end
