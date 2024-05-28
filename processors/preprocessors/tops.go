package processors

import (
	"encoding/json"
	"log"

	arubacentral "redborder.com/rb-arubacentral/rest"
)

type Campuses struct {
	Campus      []Campus `json:"campus"`
	CampusCount int      `json:"campus_count"`
}

type Campus struct {
	CampusID   string `json:"campus_id"`
	CampusName string `json:"campus_name"`
}

type CampusData struct {
	Campus        Campus     `json:"campus"`
	Buildings     []Building `json:"buildings"`
	BuildingCount int        `json:"building_count"`
}

type Building struct {
	BuildingID   string  `json:"building_id"`
	BuildingName string  `json:"building_name"`
	CampusID     string  `json:"campus_id"`
	Latitude     float64 `json:"latitude"`
	Longitude    float64 `json:"longitude"`
}

type BuildingData struct {
	Building   Building `json:"building"`
	Floors     []Floor  `json:"floors"`
	FloorCount int      `json:"floor_count"`
}

type Floor struct {
	FloorID       string  `json:"floor_id"`
	FloorName     string  `json:"floor_name"`
	BuildingID    string  `json:"building_id"`
	FloorLevel    float64 `json:"floor_level"`
	FloorWidth    float64 `json:"floor_width"`
	FloorLength   float64 `json:"floor_length"`
	CeilingHeight float64 `json:"ceiling_height"`
	Units         string  `json:"units"`
}

type FloorData struct {
	Floor            Floor         `json:"floor"`
	AccessPoints     []AccessPoint `json:"access_points"`
	AccessPointCount int           `json:"access_point_count"`
}

type AccessPoint struct {
	ApID         string  `json:"ap_id"`
	ApEthMac     string  `json:"ap_eth_mac"`
	ApName       string  `json:"ap_name"`
	FloorID      string  `json:"floor_id"`
	SerialNumber string  `json:"serial_number"`
	Model        string  `json:"model"`
	Latitude     float64 `json:"latitude"`
	Longitude    float64 `json:"longitude"`
	X            float64 `json:"x"`
	Y            float64 `json:"y"`
	Units        string  `json:"units"`
}

func GetTop(GoAruba *arubacentral.ArubaClient) (*Campuses, error) {
	campusesJSON, err := arubacentral.GetCampuses(GoAruba)
	if err != nil {
		return nil, err
	}

	var campusesData Campuses
	err = json.Unmarshal(campusesJSON, &campusesData)
	if err != nil {
		log.Printf("Error unmarshalling campuses data: %v\n", err)
		return nil, err
	}

	for i := range campusesData.Campus {
		campus := &campusesData.Campus[i]
		var campusInfoJSON []byte
		campusInfoJSON, err = arubacentral.GetCampus(GoAruba, campus.CampusID)
		if err != nil {
			log.Printf("Error getting campus info: %v\n", err)
			return nil, err
		}

		var campusData CampusData
		err = json.Unmarshal(campusInfoJSON, &campusData)
		if err != nil {
			log.Printf("Error unmarshalling campus data: %v\n", err)
			return nil, err
		}

		for j := range campusData.Buildings {
			building := &campusData.Buildings[j]
			buildingInfoJSON, err := arubacentral.GetBuilding(GoAruba, building.BuildingID)
			if err != nil {
				log.Printf("Error getting building info: %v\n", err)
				return nil, err
			}

			var buildingData BuildingData
			err = json.Unmarshal(buildingInfoJSON, &buildingData)
			if err != nil {
				log.Printf("Error unmarshalling building data: %v\n", err)
				return nil, err
			}

			for k := range buildingData.Floors {
				floor := &buildingData.Floors[k]
				accessPointsJSON, err := arubacentral.GetAps(GoAruba, floor.FloorID)
				if err != nil {
					log.Printf("Error getting access points: %v\n", err)
					return nil, err
				}

				var floorData FloorData
				err = json.Unmarshal(accessPointsJSON, &floorData)
				if err != nil {
					log.Printf("Error unmarshalling access points data: %v\n", err)
					return nil, err
				}

				// Now you have floorData ready to use
				log.Printf("Floor data: %v\n", floorData)
			}
		}
	}

	return &campusesData, nil
}
