module Grist
  module Models
    class Operateur < Organization
      attr_reader :departement_ids
      attr_accessor :departements

      def self.table_name
        "Operateurs"
      end

      def initialize(data)
        super(data)
        @departement_ids = list_values(data["fields"]["Departements"])
      end

      def migration_identifier
        "organization-operateur-#{id}"
      end

      protected

      def organization_data
        {
          migration_identifier: migration_identifier,
          category_ids: osuny_category_ids,
          localizations: {
            fr: {
              migration_identifier: l10n_migration_identifier,
              name: name
            }
          }
        }
      end

      def osuny_category_ids
        category_ids = [ENV["OSUNY_ORGANIZATION_TYPES_OPERATEURS_ID"]]
        category_ids += departements.map(&:osuny_id)
        category_ids.compact
      end
    end
  end
end
