package arubacentral

import (
	"fmt"
	"strings"
)

func ExtractCookies(headers map[string][]string) (string, string, error) {
	var session, csrfToken string
	if cookieValues, ok := headers["Set-Cookie"]; ok {
		for _, cookie := range cookieValues {
			parts := strings.SplitN(strings.TrimSpace(cookie), "=", 2)
			if len(parts) != 2 {
				continue
			}
			name, value := parts[0], parts[1]
			switch name {
			case "session":
				session = value
			case "csrftoken":
				csrfToken = value
			}
		}
	}
	if session == "" {
		return "", "", fmt.Errorf("session not found in headers")
	}
	if csrfToken == "" {
		return "", "", fmt.Errorf("CSRF token not found in headers")
	}
	return session, csrfToken, nil
}
