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

  def self.mongo_client
    Mongoid::Clients.default
  end
end
