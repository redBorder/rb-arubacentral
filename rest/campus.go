package arubacentral

import (
	"fmt"
)

func GetCampuses(GoAruba *ArubaClient) ([]byte, error) {
	return GoAruba.Get("/visualrf_api/v1/campus")
}

func GetCampus(GoAruba *ArubaClient, campusID string) ([]byte, error) {
	url := fmt.Sprintf("/visualrf_api/v1/campus/%s", campusID)
	return GoAruba.Get(url)
}
