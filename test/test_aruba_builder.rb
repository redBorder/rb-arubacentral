#######################################################################
# Copyright (c) 2023 ENEO Tecnologia S.L.
# This file is part of redBorder.
# redBorder is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# redBorder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with redBorder. If not, see <http://www.gnu.org/licenses/>.
#######################################################################

require_relative './helpers/codecov_helper'
require_relative '../bin/helpers/aruba_builder'
require 'test/unit'

class ClientDataTest < Test::Unit::TestCase
  def test_read_built_data
    client = ClientData.new
    client.write_lat(37.7749)
    client.write_long(-122.4194)
    client.write_mac_address("00:11:22:33:44:55")
    client.write_ap_mac_address("AA:BB:CC:DD:EE:FF")
    client.write_topology("Mesh")
    client.write_associated(true)
    client.write_time(Time.now)

    built_data = client.read_built_data

    assert_equal 37.7749, built_data[:lat]
    assert_equal -122.4194, built_data[:long]
    assert_equal "00:11:22:33:44:55", built_data[:client_mac_address]
    assert_equal "AA:BB:CC:DD:EE:FF", built_data[:ap_mac_address]
    assert_equal "Mesh", built_data[:topology]
    assert_equal true, built_data[:associated]
    assert_instance_of Time, built_data[:time]
  end
end

class ArubaBuilderTest < Test::Unit::TestCase
  include ArubaBuilder

  def test_build_client_data
    client_data = build_client_data do |client|
      client.write_lat(40.7128)
      client.write_long(-74.0060)
      client.write_mac_address("11:22:33:44:55:66")
      client.write_ap_mac_address("FF:EE:DD:CC:BB:AA")
      client.write_topology("Star")
      client.write_associated(false)
      client.write_time(Time.now)
    end

    assert_equal 40.7128, client_data[:lat]
    assert_equal -74.0060, client_data[:long]
    assert_equal "11:22:33:44:55:66", client_data[:client_mac_address]
    assert_equal "FF:EE:DD:CC:BB:AA", client_data[:ap_mac_address]
    assert_equal "Star", client_data[:topology]
    assert_equal false, client_data[:associated]
    assert_instance_of Time, client_data[:time]
  end
end
