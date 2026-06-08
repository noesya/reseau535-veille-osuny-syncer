module Grist
  module Models
    class Spectacle::Etape < Base
      attr_reader :spectacle_id, :lieu_id, :operator_ids,
                  :start_date, :end_date, :state, :comment
      attr_accessor :spectacle, :lieu, :operators

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
        @comment = data["fields"]["Commentaire"]
      end

      def migration_identifier
        "spectacle-etape-#{id}"
      end

    end
  end
end
