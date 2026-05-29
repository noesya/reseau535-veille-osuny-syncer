module Grist
  module Models
    class Organization < Base
      attr_reader :name

      def initialize(data)
        super(data)
        @name = data["fields"]["Nom"]
      end

      def sync_to_osuny
        api = OsunyApi::UniversityOrganizationApi.new
        response_data = api.university_organizations_upsert_post_with_http_info({
          body: {
            organizations: [
              organization_data
            ]
          },
          return_type: 'Object'
        }).first
        set_osuny_id(response_data)
      rescue OsunyApi::ApiError => e
        puts "Erreur lors de la synchronisation de l'organisation \"#{name}\": #{e.message}"
      end

      protected

      def organization_data
        raise NoMethodError, "You must implement the #{self.class.name}#organization_data instance method"
      end
    end
  end
end
