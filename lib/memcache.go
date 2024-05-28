package lib

import (
	"github.com/bradfitz/gomemcache/memcache"
)

type MemcachedClient struct {
	Client *memcache.Client
}

func NewMemcachedClient(servers []string) *MemcachedClient {
	return &MemcachedClient{
		Client: memcache.New(servers...),
	}
}

func (m *MemcachedClient) Get(key string) (string, error) {
	item, err := m.Client.Get(key)
	if err != nil {
		return "", err
	}
	return string(item.Value), nil
}

func (m *MemcachedClient) Set(key, value string) error {
	return m.Client.Set(&memcache.Item{Key: key, Value: []byte(value)})
}