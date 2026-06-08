module Grist
  module Models
    class Spectacle < Base
      attr_reader :name, :equipe_artistique_ids, :synopsis, :year, :step,
                  :discipline_ids, :thematiques_ids, :minimum_age,
                  :duration_minutes, :featured_image_url, :folder_attachment_id, :technical_sheet_attachment_id,
                  :operator_ids, :relayed_by
      attr_accessor :equipes_artistiques, :disciplines, :thematiques, :operators

      def self.table_name
        "Spectacles"
      end

      def initialize(data)
        super(data)
        @name = data["fields"]["Nom"]
        @year = data["fields"]["Annee"]
        @synopsis = "<p>" + data["fields"]["Synopsis"].to_s + "</p>"
        @featured_image_url = data["fields"]["Affiche_url_de_l_image_"]
        @discipline_ids = list_values(data["fields"]["Disciplines"])
        @thematiques_ids = list_values(data["fields"]["Thematiques"])
        @equipe_artistique_ids = list_values(data["fields"]["Createurices"])
        @step = data["fields"]["Etape"]
        @minimum_age = data["fields"]["Age_minimum"]
        @duration_minutes = data["fields"]["Duree_en_minutes_"]
        @folder_attachment_id = list_values(data["fields"]["Dossier"]).first
        @technical_sheet_attachment_id = list_values(data["fields"]["Fiche_technique"]).first
        @operator_ids = list_values(data["fields"]["Soutiens"])
        @relayed_by = data["fields"]["Relaye_par"]
      end

      def migration_identifier
        "project-spectacle-#{id}"
      end

      def osuny_category_ids
        disciplines.map(&:osuny_id) + thematiques.map(&:osuny_id)
      end

      def sync_to_osuny
        puts "Synchronisation du spectacle « #{name} » vers osuny..."
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
                    title: name,
                    summary: synopsis,
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

      def osuny_blocks
        [
          {
            migration_identifier: "#{l10n_migration_identifier}-equipes-artistiques",
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
          },
          {
            migration_identifier: "#{l10n_migration_identifier}-etapes",
            position: 2,
            title: "Étapes",
            template_kind: "organizations",
            data: {
              mode: "selection",
              layout: "large",
              elements: steps.map { |step|
                {
                  id: step.organization.osuny_id,
                  role: step.description
                }
              }
            }
          },
          {
            migration_identifier: "#{l10n_migration_identifier}-information",
            position: 3,
            title: "Informations",
            template_kind: "datatable",
            data: {
              columns: ["", ""],
              elements: [
                { cells: ["Étape", step.to_s] },
                { cells: ["Âge minimum", "#{minimum_age} ans"] },
                { cells: ["Durée", "#{duration_minutes} minutes"] },
                { cells: ["Relayé par", relayed_by.to_s] },
              ]
            }
          },
          {
            migration_identifier: "#{l10n_migration_identifier}-fichiers",
            position: 4,
            title: "Fichiers",
            template_kind: "files",
            data: {
              elements: [
                {
                  title: "Dossier",
                  file: { id: "", signed_id: "", filename: "" }
                },
                {
                  title: "Fiche technique",
                  file: { id: "", signed_id: "", filename: "" }
                }
              ]
            }
          },
          {
            migration_identifier: "#{l10n_migration_identifier}-soutiens",
            position: 5,
            title: "Soutiens",
            template_kind: "organizations",
            data: {
              mode: "selection",
              layout: "large",
              elements: operators.map { |operator|
                { id: operator.osuny_id }
              }
            }
          }
        ]
      end
    end
  end
end
