module Grist
  module Models
    module WithOsuny
      def migration_identifier
        raise NoMethodError, "You must implement the #{self.class.name}.migration_identifier instance method"
      end

      def l10n_migration_identifier
        "#{migration_identifier}-fr"
      end

      def sync_to_osuny
        puts "[#{self.class.name.split('::').last}] Synchronisation de « #{name} » vers osuny..."
        response_data = osuny_api_upsert.first
        set_osuny_id(response_data)
      rescue OsunyApi::ApiError => e
        puts "[#{self.class.name.split('::').last}] Erreur lors de la synchronisation de \"#{name}\": #{e.message}"
      end

      protected

      def osuny_api_klass
        raise NoMethodError, "You must implement the #{self.class.name}.osuny_api_klass instance method"
      end

      def osuny_api_instance
        @osuny_api_instance ||= osuny_api_klass.new
      end

      def osuny_api_upsert
        raise NoMethodError, "You must implement the #{self.class.name}.osuny_api_upsert instance method"
      end

      def set_osuny_id(response_data)
        @osuny_id = response_data.dig(:created, 0, :id) ||
                      response_data.dig(:updated, 0, :id)
      end
    end
  end
end
