package arubacentral

import (
	"fmt"
)

func GetAps(GoAruba *ArubaClient, floorID string) ([]byte, error) {
	url := fmt.Sprintf("/visualrf_api/v1/floor/%s/access_point_location", floorID)
	return GoAruba.Get(url)
}

func GetStatuses(GoAruba *ArubaClient) ([]byte, error) {
	return GoAruba.Get("/monitoring/v2/aps")
}
