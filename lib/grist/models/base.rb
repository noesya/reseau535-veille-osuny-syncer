require_relative 'with_osuny'

module Grist
  module Models
    class Base
      include WithOsuny

      SYNCABLE_DAYS_THRESHOLD = 2 # Sync only records updated in the last 2 days
      MONTH_NAMES = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]

      attr_reader :id, :last_updated_on, :synced, :_grist_data

      def self.table_name
        raise NoMethodError, "You must implement the #{self.class.name}.table_name class method"
      end

      def self.table_columns
        @table_columns ||= Grist::Client.new.get("/tables/#{self.table_name}/columns")
      end

      def self.all
        @all ||= begin
          records = Grist::Client.instance.find_all(table_name)
          records.map { |record| new(record) }
        end
      end

      def self.recently_updated
        @recently_updated ||= begin
          minimum_time_to_update = Date.today - SYNCABLE_DAYS_THRESHOLD
          all.select { |record| record.last_updated_on >= minimum_time_to_update }
        end
      end

      def self.find(id)
        all.find { |record| record.id == id }
      end

      def initialize(data)
        @_grist_data = data
        @id = data["id"]
        @synced = false
        @last_updated_on = date_value(data["fields"]["Derniere_mise_a_jour"]) || Date.today
      end

      def to_s
        raise NoMethodError, "You must implement the #{self.class.name}#to_s instance method"
      end

      protected

      # ["L", 1, 2] => [1, 2]
      def list_values(list)
        return [] unless list.is_a?(Array) && list.first == "L"
        list[1..-1]
      end

      # 1732147200 => 2024-11-21
      def date_value(value)
        return unless value.is_a?(Integer) || value.is_a?(Float)
        Time.at(value.to_i).utc.to_date
      end

      def format_date(date)
        return "" if date.nil?
        "#{date.day} #{MONTH_NAMES[date.month - 1]} #{date.year}"
      end

      def destroy_block_data(migration_identifier)
        {
          migration_identifier: migration_identifier,
          _destroy: "1"
        }
      end
    end
  end
end
