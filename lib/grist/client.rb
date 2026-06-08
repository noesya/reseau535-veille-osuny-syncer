require_relative 'models/base'
require_relative 'models/departement'
require_relative 'models/discipline'
require_relative 'models/thematique'
require_relative 'models/organisation'
require_relative 'models/spectacle'
require_relative 'models/spectacle/etape'

module Grist
  class Client
    include Singleton

    def self.api_key
      ENV['GRIST_API_KEY']
    end

    def self.api_url
      ENV['GRIST_API_URL']
    end

    def self.document_id
      ENV['GRIST_DOCUMENT_ID']
    end

    def find_all(table_name)
      response = get("/docs/#{self.class.document_id}/tables/#{table_name}/records")
      data = JSON.parse(response.body)
      data['records']
    end

    protected

    def get(path, params: {})
      uri = URI(self.class.api_url + path)
      uri.query = URI.encode_www_form(params) if params.any?

      request = Net::HTTP::Get.new(uri)

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

      response
    end
  end
end
