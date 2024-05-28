package arubacentral

import (
	"fmt"
)

const (
	getWirelessClientsPath = "/monitoring/v1/clients/wireless?offset=%d"
)

func getWirelessClients(GoAruba *ArubaClient, offset int) ([]byte, error) {
	url := fmt.Sprintf(getWirelessClientsPath, offset)
	return GoAruba.Get(url)
}
