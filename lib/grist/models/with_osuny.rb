module Grist
  module Models
    module WithOsuny
      def migration_identifier
        raise NoMethodError, "You must implement the #{self.class.name}.migration_identifier instance method"
      end

      def l10n_migration_identifier
        "#{migration_identifier}-fr"
      end

      def osuny_id
        return @osuny_id if @osuny_id
        osuny_record = find_in_osuny
        if osuny_record
          # Trouvé dans osuny, on assigne l'ID
          @osuny_id = osuny_record[:id]
        else
          # L'objet n'est pas dans osuny, on le synchronise, l'ID sera assigné automatiquement
          sync_to_osuny(minimal: true)
        end
        @osuny_id
      end

      def find_in_osuny
        puts "[#{self.class.name.split('::').last}] Recherche de « #{to_s} » dans osuny..."
        osuny_api_get.first
      rescue OsunyApi::ApiError => e
        return if e.code == 404 # L'objet n'existe pas côté osuny, on le synchronisera par la suite
        raise e
      end

      def sync_to_osuny(minimal: false)
        puts "[#{self.class.name.split('::').last}] Synchronisation de « #{to_s} » vers osuny..."
        response_data = minimal ? osuny_api_minimal_upsert.first
                                : osuny_api_upsert.first
        osuny_record_id = response_data.dig(:created, 0, :id) || response_data.dig(:updated, 0, :id)
        @osuny_id = osuny_record_id
        @synced = true unless minimal
      rescue OsunyApi::ApiError => e
        puts "[#{self.class.name.split('::').last}] Erreur lors de la synchronisation de \"#{to_s}\": #{e.message}"
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

      # Overridable to make minimal upserts
      def osuny_api_minimal_upsert
        osuny_api_upsert
      end

      def osuny_api_get
        raise NoMethodError, "You must implement the #{self.class.name}.osuny_api_get instance method"
      end
    end
  end
end
