class Place

  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize(params)
    params = params.deep_symbolize_keys()
    @id = params[:_id].to_s
    @address_components = []
    params[:address_components].each do |address|
      @address_components << AddressComponent.new(address)
    end
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])
  end

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

  def self.find_by_short_name name
    self.collection.find({
      :address_components=>{:$elemMatch => {:short_name => name}}
    })
  end

  def self.to_places items
    results = []
    items.each do |i|
      results << Place.new(i)
    end
    return results
  end
end
