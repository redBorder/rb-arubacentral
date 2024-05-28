package arubacentral

import (
	"fmt"
	"io"
	"log"
	"net/http"

	lib "redborder.com/rb-arubacentral/lib"
)

type ArubaClient struct {
	ClientID        string
	ClientSecret    string
	HTTPClient      *lib.HTTPClient
	MemcachedClient *lib.MemcachedClient
	OAuthHelper     *OAuthHelper
	Token           string
}

func NewArubaClient(endpoint, username, password, clientID, clientSecret, customerID string, memcacheServers []string) *ArubaClient {
	return &ArubaClient{
		HTTPClient:      lib.NewHTTPClient(),
		MemcachedClient: lib.NewMemcachedClient(memcacheServers),
		OAuthHelper:     NewOAuthHelper(endpoint, username, password, clientID, clientSecret, customerID),
	}
}

func (a *ArubaClient) OAuth() error {
	tokenResp, err := a.OAuthHelper.OAuth()
	if err != nil {
		fmt.Println("Error:", err)
		return err
	}
	if token, ok := tokenResp["access_token"].(string); ok {
		// Store token in memcached in order to use it
		// in other spawned services on other machines
		log.Println("Storing access_token in memcached")
		a.MemcachedClient.Set("arubacentral_access_token", token)
		a.Token = token
		return nil
	}
	return fmt.Errorf("access_token not found or not a string")
}

func (a *ArubaClient) Get(path string) ([]byte, error) {

	// Use same token for all services
	a.Token = a.MemcachedClient.Get("arubacentral_access_token")
	headers := map[string]string{
		"Authorization": fmt.Sprintf("Bearer %s", a.Token),
	}

	fullURL := fmt.Sprintf("%s%s", a.OAuthHelper.Endpoint, path)

	fmt.Println("GET", fullURL)
	resp, err := a.HTTPClient.Get(fullURL, headers)

	if err != nil {
		return nil, err
	}

	if resp.StatusCode == http.StatusUnauthorized {
		if err := a.OAuth(); err != nil {
			return nil, err
		}
		headers["Authorization"] = fmt.Sprintf("Bearer %s", a.Token)
		resp, err = a.HTTPClient.Get(fullURL, headers)
		if err != nil {
			return nil, err
		}
	}

	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return body, nil
}
