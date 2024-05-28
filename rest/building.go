package arubacentral

import (
	"fmt"
)

const (
	getBuildingPath = "/visualrf_api/v1/building/%s"
)

func GetBuilding(GoAruba *ArubaClient, buildingID string) ([]byte, error) {
	url := fmt.Sprintf(getBuildingPath, buildingID)
	return GoAruba.Get(url)
}
