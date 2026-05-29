module Grist
  module Models
    class Department < Base
      attr_reader :id, :name, :number

      def self.table_name
        "Departements"
      end

      def initialize(data)
        @id = data["id"]
        @name = data["fields"]["Nom"]
        @number = data["fields"]["Numero"]
      end

      def migration_identifier
        "organization-category-department-#{id}"
      end

      def sync_to_osuny
        api = OsunyApi::UniversityOrganizationCategoryApi.new
        api.university_organizations_categories_upsert_post({
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
          }
        })
      rescue OsunyApi::ApiError => e
        puts "Error syncing department \"#{name}\": #{e.message}"
      end
    end
  end
end
