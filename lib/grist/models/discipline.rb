module Grist
  module Models
    class Discipline < Base
      attr_reader :name

      def self.table_name
        "Disciplines"
      end

      def initialize(data)
        super(data)
        @name = data["fields"]["Nom"]
      end

      def migration_identifier
        "portfolio-category-discipline-#{id}"
      end

      def sync_to_osuny
        puts "Synchronisation de la discipline « #{name} » vers osuny..."
        api = OsunyApi::CommunicationWebsitePortfolioCategoryApi.new
        response_data = api.communication_websites_website_id_portfolio_categories_upsert_post_with_http_info(ENV["OSUNY_WEBSITE_ID"], {
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
          },
          return_type: 'Object'
        }).first
        set_osuny_id(response_data)
      rescue OsunyApi::ApiError => e
        puts "Erreur lors de la synchronisation de la discipline \"#{name}\": #{e.message}"
      end
    end
  end
end
