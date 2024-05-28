package processors

import (
	"encoding/json"

	arubacentral "redborder.com/rb-arubacentral/rest"
)

type APData struct {
	APs []struct {
		MacAddress  string `json:"macaddr"`
		Status      string `json:"status"`
		ClientCount int    `json:"client_count"`
	} `json:"aps"`
}

func ProcessApStatuses(GoAruba *arubacentral.ArubaClient) ([]byte, error) {
	data, err := arubacentral.GetStatuses(GoAruba)
	if err != nil {
		return nil, err
	}

	var apData APData
	err = json.Unmarshal(data, &apData)
	if err != nil {
		return nil, err
	}

	for i := range apData.APs {
		ap := &apData.APs[i]
		if ap.Status == "Up" {
			ap.Status = "on"
		} else {
			ap.Status = "off"
		}
	}

	accessPointsJSON, err := json.Marshal(apData.APs)
	if err != nil {
		return nil, err
	}

	return accessPointsJSON, nil
}
