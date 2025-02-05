# frozen_string_literal: true

module TestServices
  extend self

  def create_es_indexes
    Dir[Rails.root.join('app/models/elastic_*.rb').to_s].each do |filename|
      klass = File.basename(filename, '.rb').camelize.constantize
      klass.recreate_index if klass.is_a?(Indexable) && klass != ElasticBlended
    end
    logstash_index_range.each do |date|
      Es::ELK.client_reader.indices.delete(index: "logstash-#{date.strftime('%Y.%m.%d')}", ignore_unavailable: true)
      Es::ELK.client_reader.indices.create(index: "logstash-#{date.strftime('%Y.%m.%d')}")
      Es::ELK.client_reader.indices.put_alias(index: "logstash-#{date.strftime('%Y.%m.%d')}", name: "human-logstash-#{date.strftime('%Y.%m.%d')}")
    end
  end

  def delete_es_indexes
    Es::CustomIndices.client_reader.indices.delete(index: 'test-usasearch-*')
    logstash_index_range.each do |date|
      Es::ELK.client_reader.indices.delete(index: "logstash-#{date.strftime('%Y.%m.%d')}")
    end
  rescue StandardError => e
    Rails.logger.error "Error deleting es indices: #{e}"
  end

  def logstash_index_range
    end_date = Date.current
    start_date = end_date - 10.days
    start_date..end_date
  end
end
