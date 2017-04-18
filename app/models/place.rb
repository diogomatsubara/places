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

  def self.find id
    place = self.collection.find(:_id=>BSON::ObjectId.from_string(id)).first
    Place.new(place) unless place.nil?
  end

  def self.all(offset=0, limit=0)
    results = []
    self.collection.find.skip(offset).limit(limit).each do |r|
      results << Place.new(r)
    end
    return results
  end

  def destroy
    Place.collection.delete_one(:_id=>BSON::ObjectId.from_string(@id))
  end

  def self.get_address_components(sort=nil, offset=nil, limit=nil)
    query = []
    query << {:$unwind=>'$address_components'}
    query << {:$project=>
               {:_id=>1,
                :address_components=>'$address_components',
                :formatted_address=>1,
                :geometry=>{:geolocation=>'$geometry.geolocation'}
               }
             }
    query << {:$sort=>sort} unless sort.nil?
    query << {:$skip=>offset} unless offset.nil?
    query << {:$limit=>limit} unless offset.nil?
    self.collection.find.aggregate(query)
  end

  def self.get_country_names
    result = self.collection.find.aggregate([
      {:$unwind=>'$address_components'},
      {:$project=>
        {:_id=>1,
         :long_name=>'$address_components.long_name',
         :types=>'$address_components.types'
        }},
      {:$match=>{:types=>'country'}},
      {:$group=>{:_id=>'$long_name'}}
    ])
    result.to_a.map {|h| h[:_id]}
  end
end
