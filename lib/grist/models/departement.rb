module Grist
  module Models
    class Departement < Base
      attr_reader :name, :number

      def self.table_name
        "Departements"
      end

      def initialize(data)
        super(data)
        @name = data["fields"]["Nom"]
        @number = data["fields"]["Numero"]
      end

      def migration_identifier
        "organization-category-departement-#{id}"
      end

      def sync_to_osuny
        api = OsunyApi::UniversityOrganizationCategoryApi.new
        response_data = api.university_organizations_categories_upsert_post_with_http_info({
          body: {
            categories: [
              {
                migration_identifier: migration_identifier,
                parent_id: ENV["OSUNY_ORGANIZATION_DEPARTEMENTS_ID"],
                localizations: {
                  fr: {
                    migration_identifier: l10n_migration_identifier,
                    name: name
                  }
                }
              }
            ]
          },
          return_type: 'Object'
        }).first
        set_osuny_id(response_data)
      rescue OsunyApi::ApiError => e
        puts "Erreur lors de la synchronisation du département \"#{name}\": #{e.message}"
      end
    end
  end
end
