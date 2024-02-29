# frozen_string_literal: true

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

#
# Class to build client data of an aruba central client
#
class ClientData
  attr_accessor :lat, :long, :mac_address, :ap_mac_address, :topology, :associated, :time

  def initialize
    @lat = nil
    @long = nil
    @mac_address = nil
    @ap_mac_address = nil
    @topology = nil
    @associated = nil
    @time = nil
  end

  def write_lat(lat)
    @lat = lat
  end

  def write_long(long)
    @long = long
  end

  def write_mac_address(mac_address)
    @mac_address = mac_address
  end

  def write_ap_mac_address(ap_mac_address)
    @ap_mac_address = ap_mac_address
  end

  def write_topology(topology)
    @topology = topology
  end

  def write_associated(associated)
    @associated = associated
  end

  def write_time(time)
    @time = time
  end

  def read_built_data
    {
      lat: @lat,
      long: @long,
      client_mac_address: @mac_address,
      ap_mac_address: @ap_mac_address,
      topology: @topology,
      associated: @associated,
      time: @time
    }
  end
end

#
# Module to build client data of an aruba central client
#
module ArubaBuilder
  def build_client_data
    client_data = ClientData.new
    yield(client_data) if block_given?
    client_data.read_built_data
  end
end
