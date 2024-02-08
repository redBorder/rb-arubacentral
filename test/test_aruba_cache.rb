require_relative './helpers/codecov_helper'
require_relative '../lib/helpers/aruba_cache'
require 'test/unit'

# Test ArubaCache class
class ArubaCacheTest < Test::Unit::TestCase
  def setup
    @cache = ArubaCache.new
  end

  def test_fetch_caches_value_for_given_key
    @cache.fetch('test_key') { 'test_value' }
    assert_instance_of(Time, @cache.instance_variable_get(:@cache)['test_key'][:timestamp])
  end

  def test_fetch_retrieves_cached_value_for_given_key_if_not_expired
    @cache.fetch('test_key') { 'test_value' }
    assert_equal 'test_value', @cache.fetch('test_key')
  end

  def test_fetch_expires_cached_value_after_specified_expiration_time
    @cache.fetch('test_key', 1) { 'test_value' }
    sleep(2)
    assert_nil @cache.fetch('test_key')
  end

  def test_fetch_recomputes_expired_value_if_fetched_again
    @cache.fetch('test_key', 1) { 'test_value' }
    sleep(2)
    assert_equal 'new_test_value', @cache.fetch('test_key') { 'new_test_value' }
  end
end
