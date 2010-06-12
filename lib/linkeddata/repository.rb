require 'linkeddata'
require 'net/http'

module LinkedData
  class Repository < RDF::Repository

    def initialize(*args)
      @data = []
      super(*args)
    end

    def each(&block)
      @data.each(&block)
    end

    def insert_statement(statement)
      @data << statement
    end

    def delete_statement(statement)
      @data.delete(statement)
    end

    def fetched
      @fetched ||= []
    end

    def fetch(uri)
      unless fetched.include?(uri)
        Net::HTTP.start(uri.host) do |http|
          response = http.get(uri.path, 'Accept' => 'application/rdf+xml')
          fetched << uri
          if response.code == "200"
            insert(*RDF::Reader.for(:rdfxml).new(response.body, :base_uri => uri))
          end
        end
      end
    end

    def query(pattern, &block)
      case pattern
        when Hash
          query(RDF::Statement.new(pattern), &block)
        when Array
          query(RDF::Statement.new(*pattern), &block)
        when RDF::Statement
          fetch pattern.subject if pattern.subject.is_a?(RDF::URI)
          fetch pattern.object  if pattern.object.is_a?(RDF::URI)
          super(pattern, &block)
        else
          super(pattern, &block)
      end
   end
    

  end
end
