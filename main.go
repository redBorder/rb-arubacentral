package main

import (
	"fmt"
	"redborder.com/rb-arubacentral/rest"
)

func main() {
	oauth := arubacentral.NewOAuthHelper(
		"",
		"",
		"",
		"",
		"",
		"",
	)
	tokenResp, err := oauth.OAuth()
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Println("Token Response:", tokenResp)
}
