package processors

import (
	"encoding/json"
	arubacentral "redborder.com/rb-arubacentral/rest"
	preprocessors "redborder.com/rb-arubacentral/processors/preprocessors"
)


func ProcessLocations(GoAruba *arubacentral.ArubaClient) ([]byte, error) {
	tops, err := preprocessors.GetTop(GoAruba)
	if err != nil {
		return nil, err
	}

	locationsJSON, err := json.Marshal(tops)
	if err != nil {
		return nil, err
	}


	return locationsJSON, nil
}
