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

require 'thread'

# Aruba Cache class to store common requested data in-mem
class ArubaCache
  def initialize
    @cache = {}
    @mutex = Mutex.new
  end

  def fetch(key, expiration = 3600, &block)
    @mutex.synchronize do
      if @cache.key?(key) && !expired?(key)
        @cache[key][:value]
      else
        value = block_given? ? block.call : nil
        @cache[key] = { value: value, timestamp: Time.now, expiration: expiration } if value
        value
      end
    end
  end

  private

  def expired?(key)
    return false unless @cache.key?(key) && @cache[key].key?(:timestamp) && @cache[key].key?(:expiration)

    expiration_date = @cache[key][:timestamp] + @cache[key][:expiration]
    if Time.now > expiration_date
      @cache.delete(key)
      true
    else
      false
    end
  end
end
