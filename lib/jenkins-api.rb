require 'open-uri'
require 'json'

module Jenkins
  class Client
    def self.extract_path(url)
      URI(url).path
    end

    def initialize(url)
      @url = url
    end

    def load(path)
      uri = URI(url)
      uri.path = path + "/api/json"

      options = {}
      options[:http_basic_authentication] = uri.userinfo.split(':') unless uri.userinfo.nil?
      uri.userinfo = ''

      JSON.parse(open(uri, options).read)
    end

    def load_project(name)
      data = load("/job/#{name}")
      Project.new(self, data)
    end

    private

    attr_reader :url
  end

  class ApiObject
    def initialize(client, data)
      @client = client
      @data = data
    end

    protected

    attr_reader :client, :data

    private

    def method_missing(id, *args, &block)
      key = id.to_s
      if data.has_key?(key)
        data[key]
      else
        super(id, *args, &block)
      end
    end
  end

  class ChangeSet < ApiObject

    def author
      data['author']['fullName']
    end

    def comment
      data['comment']
    end
  end

  class Build < ApiObject

    def success?
      result == 'SUCCESS'
    end

    def changesets
      @changesets ||= data['changeSet']['items'].map do |data|
        ChangeSet.new client, data
      end
    end
  end

  class Project < ApiObject

    def display_name
      data['displayName']
    end

    def last_build
      @last_build ||= create_build(data['lastBuild']['url'])
    end

    def last_builds
      @last_builds ||= data['builds'].first(10).map do |d|
        create_build d['url']
      end
    end

    def health_score
      data['healthReport'].fetch(0, {}).fetch('score', 0)
    end

    private

    def create_build(url)
      data = client.load(Client.extract_path(url))
      Build.new(client, data)
    end
  end
end
