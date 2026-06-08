module Grist
  module Models
    class Spectacle::Etape < Base
      attr_reader :spectacle_id, :lieu_id, :operateur_ids,
                  :start_date, :end_date, :state, :comment
      attr_accessor :lieu, :operateurs

      def self.table_name
        "Etapes"
      end

      def initialize(data)
        super(data)
        @spectacle_id = data["fields"]["Spectacle"]
        @lieu_id = data["fields"]["Lieu"]
        @operateur_ids = list_values(data["fields"]["Operateurs"])
        @start_date = date_value(data["fields"]["Debut"])
        @end_date = date_value(data["fields"]["Fin"])
        @state = data["fields"]["Etat"]
        @comment = data["fields"]["Commentaire_public"]
      end

      def migration_identifier
        "spectacle-etape-#{id}"
      end

      def lieu
        @lieu ||= Organisation.find(lieu_id)
      end

      def operateurs
        @operateurs ||= operateur_ids.map { |operateur_id|
          Organisation.find(operateur_id)
        }.compact
      end

    end
  end
end
