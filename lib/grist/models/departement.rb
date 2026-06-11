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

      protected

      def osuny_api_klass
        OsunyApi::UniversityOrganizationCategoryApi
      end

      def osuny_api_upsert
        osuny_api_instance.university_organizations_categories_upsert_post_with_http_info({
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
        })
      end
    end
  end
end
