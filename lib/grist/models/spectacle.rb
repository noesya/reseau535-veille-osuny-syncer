module Grist
  module Models
    class Spectacle < Base
      attr_reader :title, :subtitle, :equipe_artistique_ids, :synopsis, :year, :step,
                  :discipline_ids, :thematiques_ids, :minimum_age, :duration_minutes,
                  :featured_image_url, :teaser_video_url, :files_url,
                  :operateur_ids, :comment
      attr_accessor :equipes_artistiques, :disciplines, :thematiques, :operateurs, :etapes

      def self.table_name
        "Spectacles"
      end

      def initialize(data)
        super(data)
        @title = data["fields"]["Titre"].to_s.strip
        @subtitle = data["fields"]["Sous_titre"].to_s.strip
        @equipe_artistique_ids = list_values(data["fields"]["Createurices"])
        @synopsis = data["fields"]["Synopsis"].to_s.strip
        @year = data["fields"]["Annee"]
        @step = data["fields"]["Etape"].to_s.strip
        @discipline_ids = list_values(data["fields"]["Disciplines"])
        @thematiques_ids = list_values(data["fields"]["Thematiques"])
        @minimum_age = data["fields"]["Age_minimum"]
        @duration_minutes = data["fields"]["Duree_en_minutes_"]
        @featured_image_url = data["fields"]["Affiche_url_de_l_image_"]
        @teaser_video_url = data["fields"]["Teaser_url_Youtube_"].to_s.strip
        @files_url = data["fields"]["Lien_vers_les_fichiers"].to_s.strip
        @operateur_ids = list_values(data["fields"]["Soutiens"])
        @comment = data["fields"]["Commentaire_public"].to_s.strip
      end

      def to_s
        title
      end

      def migration_identifier
        "project-spectacle-#{id}"
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

      def operateurs
        @operateurs ||= operateur_ids.map { |operateur_id|
          Organisation.find(operateur_id)
        }.compact
      end

      def etapes
        @etapes ||= begin
          unordered_etapes = Spectacle::Etape.all.select { |etape|
            etape.spectacle_id == id
          }
          unordered_etapes.sort_by { |etape|
            etape.start_date.nil? ? Float::INFINITY
                                  : etape.start_date.to_time.to_i
          }
        end
      end

      def synopsis_html
        "<p>#{synopsis}</p>"
      end

      def comment_html
        "<p>#{comment}</p>"
      end

      def information_rows
        @information_rows ||= begin
          rows = []
          rows << ["Étape", step] if step != ""
          rows << ["Âge minimum", "#{minimum_age} ans"] if minimum_age != 0
          rows << ["Durée", "#{duration_minutes} minutes"] if duration_minutes != 0
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
        osuny_api_instance.communication_websites_website_id_portfolio_projects_id_get_with_http_info(
          ENV["OSUNY_WEBSITE_ID"],
          migration_identifier,
          { return_type: 'Object' }
        )
      end

      def osuny_category_ids
        @osuny_category_ids ||= disciplines.map(&:osuny_id) + thematiques.map(&:osuny_id)
      end

      def osuny_blocks
        @osuny_blocks ||= begin
          blocks = []
          # Add all the blocks
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

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if information_rows.empty?

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Informations",
            template_kind: "title",
            data: {}
          },
          {
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
        ]
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
            title: "Fichiers",
            template_kind: "title",
            data: {}
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "call_to_action",
            data: {
              text: "Accéder aux fichiers liés au spectacle",
              elements: [
                {
                  title: "Dossier Drive",
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
        ] if operateurs.empty?

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
              layout: "large",
              elements: operateurs.map { |operateur|
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

      def blocks_comment
        block_migration_identifier = "#{l10n_migration_identifier}-comment"
        block_title_migration_identifier = "#{block_migration_identifier}-title"

        return [
          destroy_block_data(block_title_migration_identifier),
          destroy_block_data(block_migration_identifier)
        ] if comment == ""

        [
          {
            migration_identifier: block_title_migration_identifier,
            title: "Commentaire",
            template_kind: "title",
            data: {}
          },
          {
            migration_identifier: block_migration_identifier,
            title: "",
            template_kind: "chapter",
            data: {
              text: comment_html
            }
          }
        ]
      end

      def blocks_etapes
        [
          block_etapes_title,
          block_etapes_tableau,
          block_etapes_lieux,
          block_etapes_operateurs
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

      def block_etapes_tableau
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-tableau"
        return destroy_block_data(block_migration_identifier) if etapes.empty?

        {
          migration_identifier: block_migration_identifier,
          title: "",
          template_kind: "timeline",
          data: {
            layout: "vertical",
            elements: etapes.map { |etape|
              {
                title: etape.timeline_title,
                text: etape.timeline_text
              }
            }
          }
        }
      end

      def block_etapes_lieux
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-lieux"
        lieux = etapes.collect(&:lieu).compact.uniq
        return destroy_block_data(block_migration_identifier) if etapes.empty? || lieux.empty?

        {
          migration_identifier: block_migration_identifier,
          title: "Lieux",
          template_kind: "organizations",
          data: {
            mode: "selection",
            layout: "large",
            alphabetical: true,
            elements: lieux.map { |lieu|
              { id: lieu.osuny_id }
            }
          }
        }
      end

      def block_etapes_operateurs
        block_migration_identifier = "#{l10n_migration_identifier}-etapes-operateurs"
        operateurs = etapes.collect(&:operateurs).flatten.compact.uniq
        return destroy_block_data(block_migration_identifier) if etapes.empty? || operateurs.empty?

        {
          migration_identifier: block_migration_identifier,
          title: "Opérateurs",
          template_kind: "organizations",
          data: {
            mode: "selection",
            layout: "large",
            alphabetical: true,
            elements: operateurs.map { |operateur|
              { id: operateur.osuny_id }
            }
          }
        }
      end
    end
  end
end
