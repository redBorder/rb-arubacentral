package arubacentral

import (
	"fmt"
)

const (
	getCampusesPath = "/visualrf_api/v1/campus"
	getCampusPath   = "/visualrf_api/v1/campus/%s"
)

func GetCampuses(GoAruba *ArubaClient) ([]byte, error) {
	return GoAruba.Get(getCampusesPath)
}

func GetCampus(GoAruba *ArubaClient, campusID string) ([]byte, error) {
	url := fmt.Sprintf(getCampusPath, campusID)
	return GoAruba.Get(url)
}
