class Place

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client['places']
  end

  def self.load_all file
    parsed_hash = JSON.parse(file.read())
    self.collection.insert_many(parsed_hash)
  end
end
