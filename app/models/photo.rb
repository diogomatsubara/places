class Photo

  attr_accessor :id, :location
  attr_writer :contents

  def initialize(params={})
    if params[:_id]
      # initialize from params hash
      params = params.deep_symbolize_keys
      @id = params[:_id].to_s
      @location = Point.new(params[:metadata][:location])
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
      description[:metadata] = {:location=>@location.to_hash}
      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      Photo.mongo_client.database.fs.insert_one(grid_file)
      @id = grid_file.id.to_s
    end
  end

  def self.all(offset=0, limit=nil)
    result = self.mongo_client.database.fs.find.skip(offset)
    result = result.limit(limit) unless limit.nil?
    result.map {|doc| Photo.new(doc)} unless result.nil?
  end

  def self.find id
    doc = self.mongo_client.database.fs.find(
      :_id=>BSON::ObjectId.from_string(id)).first
    Photo.new(doc)
  end

  def self.mongo_client
    Mongoid::Clients.default
  end
end
