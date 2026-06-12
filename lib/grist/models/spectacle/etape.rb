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
        @comment = data["fields"]["Commentaire_public"].to_s.strip
      end

      def to_s
        "#{spectacle} - #{lieu}"
      end

      def migration_identifier
        "spectacle-etape-#{id}"
      end

      def timeline_title
        @timeline_title ||= start_date.nil? ? "Date non définie" : format_date(start_date)
      end

      def timeline_text
        return "" if timeline_text_parts.empty?
        @timeline_text ||= "<p>#{timeline_text_parts.join("<br>")}</p>"
      end

      def spectacle
        @spectacle ||= Spectacle.find(spectacle_id)
      end

      def lieu
        @lieu ||= Organisation.find(lieu_id)
      end

      def operateurs
        @operateurs ||= operateur_ids.map { |operateur_id|
          Organisation.find(operateur_id)
        }.compact
      end

      protected

      def timeline_text_parts
        @timeline_text_parts ||= begin
          parts = []
          parts << "Lieu : #{lieu.name}" if lieu
          parts << "Opérateurs : #{operateurs.map(&:name).join(", ")}" if operateurs.any?
          parts << "État : #{state}" if state
          parts << "Fin : #{format_date(end_date)}" if end_date
          parts << "Commentaire : #{comment}" if comment != ""
          parts
        end
      end

    end
  end
end
