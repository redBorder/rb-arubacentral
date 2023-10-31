require_relative './helpers/codecov_helper.rb'
require_relative '../src/helpers/aruba_math.rb'
require 'test/unit'

# Test Math Helpers
class ArubaMathHelperTest < Test::Unit::TestCase
  MARGE_ERROR = 0.001

  def test_move_coordinates_meters_north_only
    east_movement = 0
    north_movement = 100
    lat = 37.7833
    long = -122.4167

    new_lat, new_long = ArubaMathHelper.move_coordinates_meters(east_movement, north_movement, lat, long)

    assert_in_delta(37.7833550, new_lat, MARGE_ERROR)
    assert_in_delta(-122.4167, new_long, MARGE_ERROR)
  end

  def test_move_coordinates_meters_east_only
    east_movement = 100
    north_movement = 0
    lat = 37.7833
    long = -122.4167

    new_lat, new_long = ArubaMathHelper.move_coordinates_meters(east_movement, north_movement, lat, long)

    assert_in_delta(37.7833, new_lat, MARGE_ERROR)
    assert_in_delta(-122.4164558, new_long, MARGE_ERROR)
  end

  def test_move_coordinates_meters_north_and_east
    east_movement = 100
    north_movement = 100
    lat = 37.7833
    long = -122.4167

    new_lat, new_long = ArubaMathHelper.move_coordinates_meters(east_movement, north_movement, lat, long)

    assert_in_delta(37.7833550, new_lat, MARGE_ERROR)
    assert_in_delta(-122.4164558, new_long, MARGE_ERROR)
  end

  def test_calculate_distance
    xpos1 = 0
    ypos1 = 0
    xpos2 = 10
    ypos2 = 10

    distance = ArubaMathHelper.calculate_distance(xpos1, ypos1, xpos2, ypos2)

    assert_in_delta(14.142, distance, MARGE_ERROR)
  end
end
