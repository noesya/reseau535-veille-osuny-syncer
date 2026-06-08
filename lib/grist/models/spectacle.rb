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
        @title = data["fields"]["Titre"]
        @subtitle = data["fields"]["Sous_titre"]
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
          Grist::Models::Discipline.find(discipline_id)
        }.compact
      end

      def thematiques
        @thematiques ||= thematiques_ids.map { |thematique_id|
          Grist::Models::Thematique.find(thematique_id)
        }.compact
      end

      def operateurs
        @operateurs ||= operateur_ids.map { |operateur_id|
          Organisation.find(operateur_id)
        }.compact
      end

      def etapes
        @etapes ||= Spectacle::Etape.all.select { |etape|
          etape.spectacle_id == id
        }
      end

      def sync_to_osuny
        puts "Synchronisation du spectacle « #{title} » vers osuny..."
        api = OsunyApi::CommunicationWebsitePortfolioProjectApi.new
        response_data = api.communication_websites_website_id_portfolio_projects_upsert_post_with_http_info(ENV["OSUNY_WEBSITE_ID"], {
          body: {
            projects: [
              {
                migration_identifier: migration_identifier,
                year: year,
                localizations: {
                  fr: {
                    migration_identifier: l10n_migration_identifier,
                    title: title,
                    subtitle: subtitle,
                    summary: "<p>#{synopsis}</p>",
                    featured_image: { url: featured_image_url },
                    published: true,
                    published_at: Time.now,
                    category_ids: osuny_category_ids,
                    blocks: osuny_blocks
                  }
                }
              }
            ]
          },
          return_type: 'Object'
        }).first
        set_osuny_id(response_data)
      rescue OsunyApi::ApiError => e
        puts "Erreur lors de la synchronisation du spectacle \"#{name}\": #{e.message}"
      end

      protected

      def osuny_category_ids
        @osuny_category_ids ||= disciplines.map(&:osuny_id) + thematiques.map(&:osuny_id)
      end

      def osuny_blocks
        @osuny_blocks ||= [
          block_equipes_artistiques,
          block_etapes,
          block_information,
          block_files,
          block_soutiens,
          block_video,
          block_comment
        ].compact
      end

      def block_equipes_artistiques
        block_migration_identifier = "#{l10n_migration_identifier}-equipes-artistiques"
        return destroy_block_data(block_migration_identifier) if equipes_artistiques.empty?
        {
          migration_identifier: block_migration_identifier,
          position: 1,
          title: "Création",
          template_kind: "organizations",
          data: {
            mode: "selection",
            layout: "large",
            elements: equipes_artistiques.map { |equipe_artistique|
              { id: equipe_artistique.osuny_id }
            }
          }
        }
      end

      def block_etapes
        block_migration_identifier = "#{l10n_migration_identifier}-etapes"
        return destroy_block_data(block_migration_identifier) if etapes.empty?
        {
          migration_identifier: block_migration_identifier,
          position: 2,
          title: "Étapes",
          template_kind: "organizations",
          data: {
            mode: "selection",
            layout: "large",
            elements: []
          }
        }
      end

      def block_information
        block_migration_identifier = "#{l10n_migration_identifier}-information"
        rows = []
        rows << ["Étape", step] if step != ""
        rows << ["Âge minimum", "#{minimum_age} ans"] if minimum_age != 0
        rows << ["Durée", "#{duration_minutes} minutes"] if duration_minutes != 0
        return destroy_block_data(block_migration_identifier) if rows.empty?

        {
          migration_identifier: block_migration_identifier,
          position: 3,
          title: "Informations",
          template_kind: "datatable",
          data: {
            columns: ["", ""],
            elements: rows.map { |cells|
              { cells: cells }
            }
          }
        }
      end

      def block_files
        block_migration_identifier = "#{l10n_migration_identifier}-fichiers"
        return destroy_block_data(block_migration_identifier) if files_url == ""
        {
          migration_identifier: block_migration_identifier,
          position: 4,
          title: "Fichiers",
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
      end

      def block_soutiens
        block_migration_identifier = "#{l10n_migration_identifier}-soutiens"
        return destroy_block_data(block_migration_identifier) if operateurs.empty?
        {
          migration_identifier: block_migration_identifier,
          position: 5,
          title: "Soutiens",
          template_kind: "organizations",
          data: {
            mode: "selection",
            layout: "large",
            elements: operateurs.map { |operateur|
              { id: operateur.osuny_id }
            }
          }
        }
      end

      def block_video
        block_migration_identifier = "#{l10n_migration_identifier}-video"
        return destroy_block_data(block_migration_identifier) if teaser_video_url == ""
        {
          migration_identifier: block_migration_identifier,
          position: 6,
          title: "Teaser",
          template_kind: "video",
          data: {
            url: teaser_video_url
          }
        }
      end

      def block_comment
        block_migration_identifier = "#{l10n_migration_identifier}-comment"
        return destroy_block_data(block_migration_identifier) if comment == ""
        {
          migration_identifier: block_migration_identifier,
          position: 7,
          title: "Commentaire",
          template_kind: "chapter",
          data: {
            text: "<p>#{comment}</p>"
          }
        }
      end
    end
  end
end
