package processors

import (
	"encoding/json"
	"log"

	preprocessors "redborder.com/rb-arubacentral/processors/preprocessors"
	arubacentral "redborder.com/rb-arubacentral/rest"
)

func ProcessLocations(GoAruba *arubacentral.ArubaClient) ([]byte, error) {
	tops, err := preprocessors.GetTop(GoAruba)
	if err != nil {
		log.Println("Error getting tops", err)
		return nil, err
	}

	locationsJSON, err := json.Marshal(tops)
	if err != nil {
		log.Println("Error getting tops", err)
		return nil, err
	}

	return locationsJSON, nil
}
