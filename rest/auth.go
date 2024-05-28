package arubacentral

import (
	"encoding/json"
	"fmt"

	httpclient "redborder.com/rb-arubacentral/lib"
	helpers "redborder.com/rb-arubacentral/utils"
)

const (
	getSessionPath  = "%s/oauth2/authorize/central/api/login?client_id=%s"
	getAuthCodePath = "%s/oauth2/authorize/central/api/?client_id=%s&response_type=code&scope=read"
	getTokenPath    = "%s/oauth2/token"
)

type OAuthHelper struct {
	Endpoint     string
	Username     string
	Password     string
	ClientID     string
	ClientSecret string
	CustomerID   string
	HTTPClient   *httpclient.HTTPClient
}

func NewOAuthHelper(endpoint, username, password, clientID, clientSecret, customerID string) *OAuthHelper {
	return &OAuthHelper{
		Endpoint:     endpoint,
		Username:     username,
		Password:     password,
		ClientID:     clientID,
		ClientSecret: clientSecret,
		CustomerID:   customerID,
		HTTPClient:   httpclient.NewHTTPClient(),
	}
}

func (o *OAuthHelper) OAuth() (map[string]interface{}, error) {
	session, csrfToken, err := o.obtainSessionAndCSRFToken()
	if err != nil {
		return nil, err
	}

	authCode, err := o.obtainAuthorizationCode(session, csrfToken)
	if err != nil {
		return nil, err
	}

	return o.obtainAccessToken(authCode)
}

func (o *OAuthHelper) obtainSessionAndCSRFToken() (string, string, error) {
	sessionURL := fmt.Sprintf(getSessionPath, o.Endpoint, o.ClientID)
	credentials := map[string]string{"username": o.Username, "password": o.Password}
	resp, err := o.HTTPClient.Post(sessionURL, "application/json", credentials, nil)
	if err != nil {
		return "", "", err
	}
	defer resp.Body.Close()
	return helpers.ExtractCookies(resp.Header)
}

func (o *OAuthHelper) obtainAuthorizationCode(session, csrfToken string) (string, error) {
	authCodeURL := fmt.Sprintf(getAuthCodePath, o.Endpoint, o.ClientID)
	customerIDParams := map[string]string{"customer_id": o.CustomerID}
	resp, err := o.HTTPClient.Post(authCodeURL, "application/json", customerIDParams, map[string]string{"X-CSRF-Token": csrfToken, "Cookie": fmt.Sprintf("session=%s", session)})
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	var authCodeResp map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&authCodeResp); err != nil {
		return "", err
	}
	return authCodeResp["auth_code"].(string), nil
}

func (o *OAuthHelper) obtainAccessToken(authCode string) (map[string]interface{}, error) {
	tokenURL := fmt.Sprintf(getTokenPath, o.Endpoint)
	tokenBody := map[string]string{"client_id": o.ClientID, "client_secret": o.ClientSecret, "grant_type": "authorization_code", "code": authCode}
	resp, err := o.HTTPClient.Post(tokenURL, "application/json", tokenBody, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var tokenResp map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&tokenResp); err != nil {
		return nil, err
	}
	return tokenResp, nil
}
