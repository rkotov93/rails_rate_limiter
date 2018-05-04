require 'mock_redis'
require 'redis'

def mock_redis
  redis_mock = MockRedis.new
  allow(Redis).to receive(:new) { redis_mock }
  redis_mock
end
