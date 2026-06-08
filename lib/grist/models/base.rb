module Grist
  module Models
    class Base
      attr_reader :id, :osuny_id

      def self.table_name
        raise NoMethodError, "You must implement the #{self.class.name}.table_name class method"
      end

      def self.table_columns
        @table_columns ||= Grist::Client.new.get("/tables/#{self.table_name}/columns")
      end

      def self.all
        records = Grist::Client.instance.find_all(table_name)
        @all ||= records.map { |record| new(record) }
      end

      def self.find(id)
        all.find { |record| record.id == id }
      end

      def initialize(data)
        @id = data["id"]
      end

      def migration_identifier
        raise NoMethodError, "You must implement the #{self.class.name}.migration_identifier instance method"
      end

      def l10n_migration_identifier
        "#{migration_identifier}-fr"
      end

      protected

      # ["L", 1, 2] => [1, 2]
      def list_values(list)
        return [] unless list.is_a?(Array) && list.first == "L"
        list[1..-1]
      end

      def set_osuny_id(response_data)
        @osuny_id = response_data.dig(:created, 0, :id) ||
                      response_data.dig(:updated, 0, :id)
      end
    end
  end
end
