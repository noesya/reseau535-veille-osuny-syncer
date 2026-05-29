module Grist
  module Models
    class EquipeArtistique < Organization
      attr_reader :departement_ids, :email, :website
      attr_accessor :departements

      def self.table_name
        "Equipes_artistiques"
      end

      def initialize(data)
        super(data)
        @departement_ids = list_values(data["fields"]["Departement"])
        @email = data["fields"]["Mail"]
        @website = data["fields"]["Site_web"]
      end

      def migration_identifier
        "organization-equipe-artistique-#{id}"
      end

      protected

      def organization_data
        {
          migration_identifier: migration_identifier,
          category_ids: osuny_category_ids,
          email: email,
          localizations: {
            fr: {
              migration_identifier: l10n_migration_identifier,
              name: name,
              url: website
            }
          }
        }
      end

      def osuny_category_ids
        category_ids = [ENV["OSUNY_ORGANIZATION_TYPES_EQUIPES_ARTISTIQUES_ID"]]
        category_ids += departements.map(&:osuny_id)
        category_ids.compact
      end
    end
  end
end
