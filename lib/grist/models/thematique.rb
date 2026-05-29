module Grist
  module Models
    class Thematique < Base
      attr_reader :id, :name

      def self.table_name
        "Thematiques"
      end

      def initialize(data)
        @id = data["id"]
        @name = data["fields"]["Nom"]
      end

      def migration_identifier
        "portfolio-category-thematique-#{id}"
      end

      def sync_to_osuny
        api = OsunyApi::CommunicationWebsitePortfolioCategoryApi.new
        api.communication_websites_website_id_portfolio_categories_upsert_post(ENV["OSUNY_WEBSITE_ID"], {
          body: {
            categories: [
              {
                migration_identifier: migration_identifier,
                parent_id: ENV["OSUNY_PROJECT_THEMATIQUES_ID"],
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
        puts "Erreur lors de la synchronisation de la thématique \"#{name}\": #{e.message}"
      end
    end
  end
end
