package arubacentral

import (
	"fmt"
)

func GetBuilding(GoAruba *ArubaClient, buildingID string) ([]byte, error) {
	url := fmt.Sprintf("/visualrf_api/v1/building/%s", buildingID)
	return GoAruba.Get(url)
}
