module Grist
  module Models
    class Spectacle::Etape < Base
      attr_reader :spectacle_id, :lieu_id, :operator_ids,
                  :start_date, :end_date, :state, :comment
      attr_accessor :lieu, :operators

      def self.table_name
        "Etapes"
      end

      def initialize(data)
        super(data)
        @spectacle_id = data["fields"]["Spectacle"]
        @lieu_id = data["fields"]["Lieu"]
        @operator_ids = list_values(data["fields"]["Operateurs"])
        @start_date = data["fields"]["Debut"]
        @end_date = data["fields"]["Fin"]
        @state = data["fields"]["Etat"]
        @comment = data["fields"]["Commentaire_public"]
      end

      def migration_identifier
        "spectacle-etape-#{id}"
      end

      def lieu
        @lieu ||= Grist::Models::Lieu.find(lieu_id)
      end

      def operators
        @operators ||= operator_ids.map { |operator_id|
          Grist::Models::Operator.find(operator_id)
        }.compact
      end

    end
  end
end
