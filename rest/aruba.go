package arubacentral

import (
	"fmt"
	"net/http"

	httpclient "redborder.com/rb-arubacentral/lib"
)

type ArubaClient struct {
	ClientID     string
	ClientSecret string
	HTTPClient   *httpclient.HTTPClient
	OAuthHelper  *OAuthHelper
	Token        string
}

func NewArubaClient(endpoint, username, password, clientID, clientSecret, customerID string) *ArubaClient {
	return &ArubaClient{
		HTTPClient:  httpclient.NewHTTPClient(),
		OAuthHelper: NewOAuthHelper(endpoint, username, password, clientID, clientSecret, customerID),
	}
}

func (a *ArubaClient) OAuth() error {
	tokenResp, err := a.OAuthHelper.OAuth()
	if err != nil {
		fmt.Println("Error:", err)
		return err
	}
	if token, ok := tokenResp["access_token"].(string); ok {
		a.Token = token
		return nil
	}
	return fmt.Errorf("access_token not found or not a string")
}

func (a *ArubaClient) Get(path string) (*http.Response, error) {
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

	return resp, nil
}
