package main

import (
	"fmt"
	"io/ioutil"

	arubacentral "redborder.com/rb-arubacentral/rest"
)

func main() {
	ArubaClient := arubacentral.NewArubaClient(
		"",
		"",
		"",
		"",
		"",
		"",
	)
	resp, err := ArubaClient.Get("/visualrf_api/v1/campus")

	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	fmt.Println("Response Status:", resp.Status)
	fmt.Println("Response Headers:", resp.Header)
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}
	fmt.Println("Response Body:", string(body))

}
