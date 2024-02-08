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

# Aruba Cache class to store common requested data in-mem
class ArubaCache
  def initialize
    @cache = {}
    @mutex = Mutex.new
  end

  def fetch(key, expiration = 3600, store_in_cache = false) # rubocop:disable Style/OptionalBooleanParameter
    @mutex.synchronize do
      return cached_value(key, store_in_cache) if cache_contains_valid_data?(key) && !block_given?

      if should_fetch_from_block?(key, store_in_cache)
        value = block_given? ? yield : nil
        cache_value(key, value, expiration) if value && store_in_cache
        value
      else
        cached_value(key, store_in_cache)
      end
    end
  end

  private

  def cache_contains_valid_data?(key)
    @cache.key?(key) && !expired?(key)
  end

  def should_fetch_from_block?(key, store_in_cache)
    !store_in_cache || (!@cache.key?(key) || expired?(key))
  end

  def cached_value(key, _store_in_cache)
    @cache[key][:value]
  end

  def cache_value(key, value, expiration)
    @cache[key] = { value: value, timestamp: Time.now, expiration: expiration }
  end

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
