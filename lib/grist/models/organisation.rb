module Grist
  module Models
    class Organisation < Base
      attr_reader :name, :departement_ids, :operateur_ids,
                  :address, :zipcode, :city, :email, :website,
                  :is_equipe_artistique, :is_operateur, :is_lieu, :is_membre_535
      attr_accessor :departements, :operateurs, :operating_organisations

      def self.table_name
        "Organisations"
      end

      def initialize(data)
        super(data)
        @name = data["fields"]["Nom"]
        @departement_ids = list_values(data["fields"]["Departements"])
        @operateur_ids = list_values(data["fields"]["Operateurs"]) - [id] # On évite de se référencer soi-même
        @address = data["fields"]["Adresse"]
        @zipcode = data["fields"]["Code_postal"]
        @city = data["fields"]["Ville"]
        @email = data["fields"]["Mail"]
        @website = data["fields"]["Site_web"]
        @is_equipe_artistique = data["fields"]["Equipe_artistique"]
        @is_operateur = data["fields"]["Operateur"]
        @is_lieu = data["fields"]["Lieu"]
        @is_membre_535 = data["fields"]["Membre_535"]
      end

      def to_s
        name
      end

      def migration_identifier
        "organisation-#{id}"
      end

      def departements
        @departements ||= departement_ids.map { |departement_id|
          Departement.find(departement_id)
        }.compact
      end

      def operateurs
        @operateurs ||= operateur_ids.map { |operateur_id|
          Organisation.find(operateur_id)
        }.compact
      end

      def operating_organisations
        @operating_organisations ||= Organisation.all.select { |organisation|
          organisation.operateur_ids.include?(self.id)
        }
      end

      protected

      def osuny_api_klass
        OsunyApi::UniversityOrganizationApi
      end

      def osuny_api_upsert
        osuny_api_instance.university_organizations_upsert_post_with_http_info({
          body: {
            organizations: [
              {
                migration_identifier: migration_identifier,
                category_ids: osuny_category_ids,
                email: email,
                address: address,
                zipcode: zipcode,
                city: city,
                localizations: {
                  fr: {
                    migration_identifier: l10n_migration_identifier,
                    name: name,
                    url: website
                  }
                }
              }
            ]
          },
          return_type: 'Object'
        })
      end

      def osuny_api_get
        osuny_api_instance.university_organizations_id_get_with_http_info(
          migration_identifier,
          { return_type: 'Object' }
        )
      end

      def osuny_category_ids
        category_ids = []
        category_ids << ENV["OSUNY_ORGANIZATION_TYPES_EQUIPES_ARTISTIQUES_ID"] if is_equipe_artistique
        category_ids << ENV["OSUNY_ORGANIZATION_TYPES_OPERATEURS_ID"] if is_operateur
        category_ids << ENV["OSUNY_ORGANIZATION_TYPES_LIEUX_ID"] if is_lieu
        category_ids << ENV["OSUNY_ORGANIZATION_TYPES_MEMBRES_535_ID"] if is_membre_535
        category_ids += departements.map(&:osuny_id)
        category_ids.compact
      end
    end
  end
end
