package main

import (
	"fmt"

	arubacentral "redborder.com/rb-arubacentral/rest"
)

func main() {
	GoAruba := arubacentral.NewArubaClient(
		"",
		"",
		"",
		"",
		"",
		"",
	)
	resp, err := GoAruba.Get("/visualrf_api/v1/campus")

	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Println("Response:", string(resp))
}
