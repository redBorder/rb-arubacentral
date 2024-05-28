package arubacentral

import (
	"fmt"
)

const (
	getApsPath      = "/visualrf_api/v1/floor/%s/access_point_location"
	getStatusesPath = "/monitoring/v2/aps"
)

func GetAps(GoAruba *ArubaClient, floorID string) ([]byte, error) {
	url := fmt.Sprintf(getApsPath, floorID)
	return GoAruba.Get(url)
}

func GetStatuses(GoAruba *ArubaClient) ([]byte, error) {
	return GoAruba.Get(getStatusesPath)
}
