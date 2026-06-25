module Grist
  module Models
    class Spectacle::Etape::Etat < Base
      attr_reader :name

      def self.table_name
        "Etats_d_etape"
      end

      def initialize(data)
        super(data)
        @name = data["fields"]["Nom"]
      end

      def to_s
        name
      end

      def migration_identifier
        "agenda-category-etat-#{id}"
      end

      protected

      def osuny_api_klass
        OsunyApi::CommunicationWebsiteAgendaCategoryApi
      end

      def osuny_api_upsert
        osuny_api_instance.communication_websites_website_id_agenda_categories_upsert_post_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          {
            body: {
              categories: [
                {
                  migration_identifier: migration_identifier,
                  parent_id: ENV["OSUNY_AGENDA_ETATS_ID"],
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
          }
        )
      end

      def osuny_api_get
        osuny_api_instance.communication_websites_website_id_agenda_categories_id_get_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          migration_identifier,
          { return_type: 'Object' }
        )
      end

    end
  end
end
