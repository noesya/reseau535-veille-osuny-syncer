module Grist
  module Models
    class Spectacle < Base
      attr_reader :title, :equipe_artistique_ids, :synopsis, :presentation, :year,
                  :state_id, :discipline_ids, :thematiques_ids,
                  :minimum_age, :duration_minutes, :ideal_playground, :details, :technical_needs,
                  :featured_image_url, :teaser_video_url, :files_url,
                  :is_archive
      attr_accessor :equipes_artistiques, :disciplines, :thematiques, :etapes

      def self.table_name
        "Spectacles"
      end

      def initialize(data)
        super(data)
        @title = data["fields"]["Titre"].to_s.strip
        @equipe_artistique_ids = list_values(data["fields"]["Createurices"])
        @synopsis = data["fields"]["Synopsis"].to_s.strip
        @presentation = data["fields"]["Presentation"].to_s.strip
        @year = data["fields"]["Annee"]
        @state_id = data["fields"]["Etat"]
        @discipline_ids = list_values(data["fields"]["Disciplines"])
        @thematiques_ids = list_values(data["fields"]["Thematiques"])
        @minimum_age = data["fields"]["Age_minimum"]
        @duration_minutes = data["fields"]["Duree_en_minutes_"]
        @ideal_playground = data["fields"]["Espace_de_jeu_ideal"].to_s.strip
        @details = data["fields"]["Precisions"].to_s.strip
        @technical_needs = data["fields"]["Besoins_techniques"].to_s.strip
        # Unescape the URL as osuny will escape it on its side
        @featured_image_url = URI::Parser.new.unescape(data["fields"]["Affiche_url_de_l_image_"].to_s)
        @teaser_video_url = data["fields"]["Teaser_url_Youtube_"].to_s.strip
        @files_url = data["fields"]["Documentation"].to_s.strip
        @is_archive = data["fields"]["Mis_en_archive"]
      end

      def to_s
        title
      end

      def migration_identifier
        "project-spectacle-#{id}"
      end

      def state
        return unless state_id
        @state ||= Spectacle::Etat.find(state_id)
      end

      def equipes_artistiques
        @equipes_artistiques ||= equipe_artistique_ids.map { |equipe_artistique_id|
          Organisation.find(equipe_artistique_id)
        }.compact
      end

      def disciplines
        @disciplines ||= discipline_ids.map { |discipline_id|
          Discipline.find(discipline_id)
        }.compact
      end

      def thematiques
        @thematiques ||= thematiques_ids.map { |thematique_id|
          Thematique.find(thematique_id)
        }.compact
      end

      def supporting_operateurs
        @supporting_operateurs ||= begin
          residency_etapes = etapes.select { |etape| etape.etat.to_s == "Résidence" }
          residency_etapes.map(&:operateurs).flatten.compact
        end
      end

      def etapes
        @etapes ||= begin
          unordered_etapes = Spectacle::Etape.all.select { |etape|
            etape.spectacle_id == id
          }
          unordered_etapes.sort_by { |etape|
            etape.start_date.nil? ? -Float::INFINITY
                                  : -etape.start_date.to_time.to_i
          }
        end
      end

      def dated_etapes
        @dated_etapes ||= etapes.select(&:dated?)
      end

      def subtitle
        equipes_artistiques.map(&:to_s).join(", ")
      end

      def presentation_html
        "<p>#{presentation}</p>"
      end

      def synopsis_html
        "<p>#{synopsis}</p>"
      end

      def technical_needs_html
        "<p>#{technical_needs}</p>"
      end

      def information_rows
        @information_rows ||= begin
          rows = []
          rows << ["Âge minimum", "#{minimum_age} ans"] if minimum_age != 0
          rows << ["Durée", "#{duration_minutes} minutes"] if duration_minutes != 0
          rows << ["Terrain de jeu idéal", ideal_playground] if ideal_playground != ""
          rows << ["Précisions", details] if details != ""
          rows
        end
      end

      protected

      def osuny_api_klass
        OsunyApi::CommunicationWebsitePortfolioProjectApi
      end

      def osuny_api_upsert
        osuny_api_instance.communication_websites_website_id_portfolio_projects_upsert_post_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          {
            body: {
              projects: [
                {
                  migration_identifier: migration_identifier,
                  year: year,
                  category_ids: osuny_category_ids,
                  full_width: false,
                  localizations: {
                    fr: {
                      migration_identifier: l10n_migration_identifier,
                      title: title,
                      subtitle: subtitle,
                      summary: synopsis_html,
                      featured_image: { url: featured_image_url },
                      published: !is_archive,
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

      # Minimal upsert to sync etapes
      # Unpublished, without featured image, categories and blocks
      def osuny_api_minimal_upsert
        osuny_api_instance.communication_websites_website_id_portfolio_projects_upsert_post_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          {
            body: {
              projects: [
                {
                  migration_identifier: migration_identifier,
                  year: year,
                  full_width: false,
                  localizations: {
                    fr: {
                      migration_identifier: l10n_migration_identifier,
                      title: title,
                      subtitle: subtitle,
                      summary: synopsis_html,
                      published: false
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
        osuny_api_instance.communication_websites_website_id_portfolio_projects_id_get_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          migration_identifier,
          { return_type: 'Object' }
        )
      end

      def osuny_category_ids
        @osuny_category_ids ||= begin
          category_ids = []
          category_ids << state.osuny_id if state
          category_ids.concat(disciplines.map(&:osuny_id))
          category_ids.concat(thematiques.map(&:osuny_id))
          category_ids
        end
      end

      def osuny_blocks
        @osuny_blocks ||= begin
          blocks = []
          # Add all the blocks
          blocks << block_presentation
          blocks.concat(blocks_equipes_artistiques)
          blocks.concat(blocks_information)
          blocks.concat(blocks_files)
          blocks.concat(blocks_soutiens)
          blocks.concat(blocks_video)
          blocks.concat(blocks_comment)
          blocks.concat(blocks_etapes)
          # Set the positions
          blocks.each_with_index { |block, index|
            block[:position] = index + 1
          }
          blocks
        end
      end

      def block_presentation
        block_migration_identifier = "#{l10n_migration_identifier}-presentation"
        return destroy_block_data(block_migration_identifier) if presentation == ""

        {
          migration_identifier: block_migration_identifier,
          title: "",
          template_kind: "chapter",
          layout: "accent_background",
          data: {
            text: presentation_html
          }
        }
      end

      def blocks_equipes_artistiques
        block_migration_identifier = "#{l10n_migration_identifier}-equipes-artistiques"
        block_title_migration_identifier = "#{block_migration_identifier}-title"

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if equipes_artistiques.empty?

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Création",
            template_kind: "title",
            data: {}
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "organizations",
            data: {
              mode: "selection",
              layout: "large",
              elements: equipes_artistiques.map { |equipe_artistique|
                { id: equipe_artistique.osuny_id }
              }
            }
          }
        ]
      end

      def blocks_information
        block_migration_identifier = "#{l10n_migration_identifier}-information"
        block_title_migration_identifier = "#{block_migration_identifier}-title"
        block_technical_needs_migration_identifier = "#{l10n_migration_identifier}-besoins-techniques"

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier),
          destroy_block_data(block_technical_needs_migration_identifier)
        ] if information_rows.empty? && technical_needs == ""

        blocks = [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Informations",
            template_kind: "title",
            data: {}
          }
        ]

        if information_rows.empty?
          blocks << destroy_block_data(block_migration_identifier)
        else
          blocks << {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "datatable",
            data: {
              columns: ["", ""],
              elements: information_rows.map { |cells|
                { cells: cells }
              }
            }
          }
        end

        if technical_needs == ""
          blocks << destroy_block_data(block_technical_needs_migration_identifier)
        else
          blocks << {
            migration_identifier: block_technical_needs_migration_identifier,
            title: "Besoins techniques",
            template_kind: "chapter",
            data: {
              text: technical_needs_html
            }
          }
        end

        blocks
      end

      def blocks_files
        block_migration_identifier = "#{l10n_migration_identifier}-fichiers"
        block_title_migration_identifier = "#{block_migration_identifier}-title"

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if files_url == ""

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Documentation",
            template_kind: "title",
            data: {}
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "call_to_action",
            data: {
              layout: "no_background",
              text: "",
              elements: [
                {
                  title: "Toutes les informations",
                  url: files_url,
                  target_blank: true
                }
              ]
            }
          }
        ]
      end

      def blocks_soutiens
        block_migration_identifier = "#{l10n_migration_identifier}-soutiens"
        block_title_migration_identifier = "#{block_migration_identifier}-title"

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if supporting_operateurs.empty?

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Soutiens",
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
              elements: supporting_operateurs.map { |operateur|
                { id: operateur.osuny_id }
              }
            }
          }
        ]
      end

      def blocks_video
        block_migration_identifier = "#{l10n_migration_identifier}-video"
        block_title_migration_identifier = "#{block_migration_identifier}-title"

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if teaser_video_url == ""

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Teaser",
            template_kind: "title",
            data: {}
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "video",
            data: {
              url: teaser_video_url
            }
          }
        ]
      end

      # LEGACY
      # TODO: Remove when blocks are removed on production
      def blocks_comment
        block_migration_identifier = "#{l10n_migration_identifier}-comment"
        block_title_migration_identifier = "#{block_migration_identifier}-title"

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ]
      end

      def blocks_etapes
        [
          block_etapes_title,
          block_etapes_list,
          block_etapes_tableau, # Legacy, remove after destroy sync
          block_etapes_lieux, # Legacy, remove after destroy sync
          block_etapes_operateurs # Legacy, remove after destroy sync
        ]
      end

      def block_etapes_title
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-titre"
        return destroy_block_data(block_migration_identifier) if etapes.empty?
        {
          migration_identifier: block_migration_identifier,
          title: "Vie du spectacle",
          template_kind: "title",
          data: {}
        }
      end

      def block_etapes_list
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-list"
        return destroy_block_data(block_migration_identifier) if dated_etapes.empty?

        {
          migration_identifier: block_migration_identifier,
          title: "",
          template_kind: "agenda",
          data: {
            layout: "list",
            mode: "selection",
            option_categories: true,
            option_dates: true,
            option_image: true,
            option_subtitle: false,
            option_summary: true,
            option_status: false,
            elements: dated_etapes.map { |etape|
              { id: etape.osuny_id }
            }
          }
        }
      end

      def block_etapes_tableau
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-tableau"
        destroy_block_data(block_migration_identifier)
      end

      def block_etapes_lieux
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-lieux"
        destroy_block_data(block_migration_identifier)
      end

      def block_etapes_operateurs
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-operateurs"
        destroy_block_data(block_migration_identifier)
      end
    end
  end
end
