module ArubaMathHelper

    def self.move_coordinates_meters(east_movement, north_movement, lat, long)
        earth_major_radius = 6378137.0
        earth_minor_radius = 6356752.3
        radians_to_degrees = 180 / Math::PI
        change_lat = north_movement / earth_minor_radius * radians_to_degrees
        change_long = east_movement / (earth_major_radius * Math.cos(lat / radians_to_degrees)) * radians_to_degrees
        new_lat = lat + change_lat
        new_long = long + change_long
        return new_lat, new_long
    end

    def self.calculate_distance(x1, y1, x2, y2)
        Math.sqrt((x1 - x2)**2 + (y1 - y2)**2)
    end

end