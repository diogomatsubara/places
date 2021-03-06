class Photo

  attr_accessor :id, :location, :place
  attr_writer :contents

  def initialize(params={})
    if params[:_id]
      # initialize from params hash
      params = params.deep_symbolize_keys
      @id = params[:_id].to_s
      @location = Point.new(params[:metadata][:location])
      @place = params[:metadata][:place]
    end
  end

  def place
    @place.nil? ? @place : Place.find(@place.to_s)
  end

  def place=(value)
    case
    when value.is_a?(BSON::ObjectId)
      @place = value
    when value.is_a?(Place)
      @place = BSON::ObjectId.from_string(value.id)
    when value.is_a?(String)
      @place = BSON::ObjectId.from_string(value)
    else
      @place = nil
    end
  end

  def persisted?
    !@id.nil?
  end

  def save
    if !persisted?
      @contents.rewind
      gps = EXIFR::JPEG.new(@contents).gps
      @location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
      description = {}
      description[:content_type] = "image/jpeg"
      description[:metadata] = {
        :location=>@location.to_hash, :place=>@place}
      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      self.class.mongo_client.database.fs.insert_one(grid_file)
      @id = grid_file.id.to_s
    else
      self.class.mongo_client.database.fs.find(
        :_id=>BSON::ObjectId.from_string(@id)).update_one(
          :metadata=>{:location=>@location.to_hash, :place=>@place})
    end
  end

  def self.all(offset=0, limit=nil)
    result = self.mongo_client.database.fs.find.skip(offset)
    result = result.limit(limit) unless limit.nil?
    result.map {|doc| self.new(doc)} unless result.nil?
  end

  def self.find id
    doc = self.mongo_client.database.fs.find(
      :_id=>BSON::ObjectId.from_string(id)).first
    return doc.nil? ? nil : Photo.new(doc)
  end

  def contents
    f = self.class.mongo_client.database.fs.find_one(
      :_id=>BSON::ObjectId.from_string(@id))
    if f
      buffer = ""
      f.chunks.reduce([]) do |x, chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  def destroy
    self.class.mongo_client.database.fs.find(
      :_id=>BSON::ObjectId.from_string(@id)).delete_one
  end

  def find_nearest_place_id max_distance
    doc = Place.near(@location, max_distance).limit(1).projection(:_id=>1).first
    return id.nil? ? nil : doc[:_id]
  end

  def self.find_photos_for_place place_id
    self.mongo_client.database.fs.find(
      :"metadata.place"=>BSON::ObjectId.from_string(place_id.to_s))
  end

  def self.mongo_client
    Mongoid::Clients.default
  end
end
