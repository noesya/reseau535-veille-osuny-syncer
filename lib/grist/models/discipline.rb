module Grist
  module Models
    class Discipline < Base
      attr_reader :id, :name, :number

      def self.table_name
        "Disciplines"
      end

      def initialize(data)
        @id = data["id"]
        @name = data["fields"]["Nom"]
      end

      def migration_identifier
        "portfolio-category-discipline-#{id}"
      end

      def sync_to_osuny
        api = OsunyApi::CommunicationWebsitePortfolioCategoryApi.new
        api.communication_websites_website_id_portfolio_categories_upsert_post(ENV["OSUNY_WEBSITE_ID"], {
          body: {
            categories: [
              {
                migration_identifier: migration_identifier,
                parent_id: ENV["OSUNY_PROJECT_DISCIPLINES_ID"],
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
        puts "Error syncing discipline \"#{name}\": #{e.message}"
      end
    end
  end
end
