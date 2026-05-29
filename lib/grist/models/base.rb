module Grist
  module Models
    class Base
      def self.table_name
        raise NoMethodError, "You must implement the #{self.class.name}.table_name class method"
      end

      def self.table_columns
        @table_columns ||= Grist::Client.new.get("/tables/#{self.table_name}/columns")
      end

      def migration_identifier
        raise NoMethodError, "You must implement the #{self.class.name}.migration_identifier instance method"
      end

      def l10n_migration_identifier
        "#{migration_identifier}-fr"
      end
    end
  end
end
