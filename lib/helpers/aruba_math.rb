# Aruba central Math helpers to do some operations
module ArubaMathHelper
  def self.move_coordinates_meters(east_movement, north_movement, lat, long)
    earth_major_radius = 6_378_137.0
    earth_minor_radius = 6_356_752.3
    radians_to_degrees = 180 / Math::PI
    change_lat = north_movement / earth_minor_radius * radians_to_degrees
    change_long = east_movement / (earth_major_radius * Math.cos(lat / radians_to_degrees)) * radians_to_degrees
    new_lat = lat + change_lat
    new_long = long + change_long
    [new_lat, new_long]
  end

  def self.calculate_distance(xpos1, ypos1, xpos2, ypos2)
    Math.sqrt((xpos1 - xpos2)**2 + (ypos1 - ypos2)**2)
  end
end
