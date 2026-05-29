require_relative 'models/base'
require_relative 'models/departement'
require_relative 'models/discipline'
require_relative 'models/thematique'
require_relative 'models/organization'
require_relative 'models/equipe_artistique'

module Grist
  class Client
    def self.api_key
      ENV['GRIST_API_KEY']
    end

    def self.api_url
      ENV['GRIST_API_URL']
    end

    def self.document_id
      ENV['GRIST_DOCUMENT_ID']
    end

    def load_departements
      find_all(Grist::Models::Departement)
    end

    def load_disciplines
      find_all(Grist::Models::Discipline)
    end

    def load_thematiques
      find_all(Grist::Models::Thematique)
    end

    def load_equipes_artistiques
      find_all(Grist::Models::EquipeArtistique)
    end

    protected

    def find_all(model_klass)
      results = get("/docs/#{self.class.document_id}/tables/#{model_klass.table_name}/records")
      results['records'].map { |record| model_klass.new(record) }
    end

    def get(path, params: {})
      uri = URI(self.class.api_url + path)
      uri.query = URI.encode_www_form(params) if params.any?

      request = Net::HTTP::Get.new(uri)

      self.request(request)
    end

    def post(path, body: {})
      uri = URI(self.class.api_url + path)

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(body)

      self.request(request)
    end

    def request(request)
      puts "Making API request to #{request.method} #{request.uri}"
      request['Authorization'] = "Bearer #{self.class.api_key}"

      response = Net::HTTP.start(request.uri.hostname, request.uri.port, use_ssl: request.uri.scheme == 'https') do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "API request failed with status #{response.code}: #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end
