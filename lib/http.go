package lib

import (
	"bytes"
	"encoding/json"
	"net/http"
	"sync"
)

type HTTPClient struct {
	client *http.Client
	pool   sync.Pool
}

func NewHTTPClient() *HTTPClient {
	return &HTTPClient{
		client: &http.Client{},
		pool: sync.Pool{
			New: func() interface{} {
				return &http.Client{}
			},
		},
	}
}

func (c *HTTPClient) Get(url string, headers map[string]string) (*http.Response, error) {
	client := c.pool.Get().(*http.Client)
	defer c.pool.Put(client)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	for key, value := range headers {
		req.Header.Set(key, value)
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	return resp, nil
}

func (c *HTTPClient) Post(url string, contentType string, body map[string]string, headers map[string]string) (*http.Response, error) {
	client := c.pool.Get().(*http.Client)
	defer c.pool.Put(client)

	jsonBody, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", contentType)
	for key, value := range headers {
		req.Header.Set(key, value)
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	return resp, nil
}
