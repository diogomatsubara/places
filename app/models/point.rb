class Point

  attr_accessor :longitude, :latitude

  def initialize(params)
    params = params.symbolize_keys()
    @longitude = params[:type].nil? ? params[:lng] : params[:coordinates][0]
    @latitude = params[:type].nil? ? params[:lat] : params[:coordinates][1]
  end

  def to_hash
    # return a GeoJSON Point hash
    {:type=>"Point", :coordinates=>[@longitude, @latitude]}
  end


end
