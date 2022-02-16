require "kafka"

module Imdbak
  module Kfk
    class << self
      def client
        @kafka ||= Kafka.new(["localhost:9093"], client_id: "imdbak")
      end
    end
  end
end
