module Grist
  module Models
    class Spectacle::Etape < Base
      attr_reader :spectacle_id, :lieu_id, :operateur_ids,
                  :start_date, :end_date, :etat_id, :comment
      attr_accessor :spectacle, :lieu, :operateurs, :etat

      def self.table_name
        "Etapes"
      end

      def self.started_or_ended_recently
        valid_dates = [Date.today - 1, Date.today]
        all.select { |etape|
          etape.start_date && etape.end_date && (
            valid_dates.include?(etape.start_date) ||
            valid_dates.include?(etape.end_date)
          )
        }
      end

      def initialize(data)
        super(data)
        @spectacle_id = data["fields"]["Spectacle"]
        @lieu_id = data["fields"]["Lieu"]
        @operateur_ids = list_values(data["fields"]["Operateurs"])
        @start_date = date_value(data["fields"]["Debut"])
        @end_date = date_value(data["fields"]["Fin"])
        @etat_id = data["fields"]["Etat"]
        @comment = data["fields"]["Commentaire_public"].to_s.strip
      end

      def to_s
        "#{spectacle} - #{lieu}"
      end

      def migration_identifier
        "spectacle-etape-#{id}"
      end

      def spectacle
        @spectacle ||= Spectacle.find(spectacle_id)
      end

      def lieu
        @lieu ||= Organisation.find(lieu_id)
      end

      def operateurs
        @operateurs ||= operateur_ids.map { |operateur_id|
          Organisation.find(operateur_id)
        }.compact
      end

      def etat
        @etat ||= Spectacle::Etape::Etat.find(etat_id)
      end

      def summary
        return if lieu.nil? && operateurs.empty?
        @summary ||= begin
          operateurs_sentence = operateurs.map(&:to_s).join(', ')
          if lieu.nil?
            operateurs_sentence
          else
            "#{lieu} (#{operateurs_sentence})"
          end
        end
      end

      def comment_html
        "<p>#{comment}</p>"
      end

      def dated?
        start_date && end_date
      end

      def sync_to_osuny(minimal: false)
        # On ne synchronise que les étapes avec des dates
        super if spectacle && dated?
      end

      protected

      def osuny_api_klass
        OsunyApi::CommunicationWebsiteAgendaEventApi
      end

      def osuny_api_upsert
        osuny_api_instance.communication_websites_website_id_agenda_events_upsert_post_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          {
            body: {
              events: [
                {
                  migration_identifier: migration_identifier,
                  from_day: start_date,
                  to_day: end_date,
                  category_ids: osuny_category_ids,
                  localizations: {
                    fr: {
                      migration_identifier: l10n_migration_identifier,
                      title: spectacle.title,
                      subtitle: spectacle.subtitle,
                      summary: summary,
                      featured_image: { url: spectacle.featured_image_url },
                      published: true,
                      blocks: osuny_blocks
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
        osuny_api_instance.communication_websites_website_id_agenda_events_id_get_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          migration_identifier,
          { return_type: 'Object' }
        )
      end

      def osuny_category_ids
        @osuny_category_ids ||= [etat&.osuny_id].compact
      end

      def osuny_blocks
        @osuny_blocks ||= begin
          blocks = []
          # Add all the blocks
          blocks << block_comment
          blocks.concat(blocks_operateurs)
          blocks.concat(blocks_spectacle)
          blocks.concat(blocks_lieu)
          # Set the positions
          blocks.each_with_index { |block, index|
            block[:position] = index + 1
          }
          blocks
        end
      end

      def block_comment
        block_migration_identifier = "#{l10n_migration_identifier}-comment"
        return destroy_block_data(block_migration_identifier) if comment == ""

        {
          migration_identifier: block_migration_identifier,
          title: "",
          template_kind: "chapter",
          layout: "accent_background",
          data: {
            text: comment_html
          }
        }
      end

      def blocks_spectacle
        block_migration_identifier = "#{l10n_migration_identifier}-spectacle"
        block_title_migration_identifier = "#{block_migration_identifier}-title"

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Le spectacle",
            template_kind: "title",
            data: {}
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "projects",
            data: {
              mode: "selection",
              layout: "large",
              option_categories: true,
              option_image: true,
              option_subtitle: true,
              option_summary: false,
              option_year: false,
              elements: [
                { id: spectacle.osuny_id }
              ]
            }
          }
        ]
      end

      def blocks_lieu
        block_migration_identifier = "#{l10n_migration_identifier}-lieu"
        block_title_migration_identifier = "#{block_migration_identifier}-title"
        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if lieu.nil?

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Le lieu",
            template_kind: "title",
            data: {
              layout: "collapsed"
            }
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "organizations",
            data: {
              mode: "selection",
              layout: "grid",
              elements: [
                { id: lieu.osuny_id }
              ]
            }
          }
        ]
      end

      def blocks_operateurs
        block_migration_identifier = "#{l10n_migration_identifier}-operateurs"
        block_title_migration_identifier = "#{block_migration_identifier}-title"
        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if lieu.nil?

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Organisateurs",
            template_kind: "title",
            data: {}
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "organizations",
            data: {
              mode: "selection",
              layout: "grid",
              elements: operateurs.map { |operateur|
                { id: operateur.osuny_id }
              }
            }
          }
        ]
      end

    end
  end
end
