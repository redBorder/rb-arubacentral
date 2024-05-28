package arubacentral

import (
	"math"
)

type ArubaMathHelper struct{}

func (a *ArubaMathHelper) MoveCoordinatesMeters(eastMovement, northMovement, lat, long float64) (float64, float64) {
	earthMajorRadius := 6378137.0
	earthMinorRadius := 6356752.3
	radiansToDegrees := 180 / math.Pi
	changeLat := northMovement / earthMinorRadius * radiansToDegrees
	changeLong := eastMovement / (earthMajorRadius * math.Cos(lat/radiansToDegrees)) * radiansToDegrees
	newLat := lat + changeLat
	newLong := long + changeLong
	return newLat, newLong
}

func (a *ArubaMathHelper) CalculateDistanceSquared(xpos1, ypos1, xpos2, ypos2 float64) float64 {
	dx := xpos1 - xpos2
	dy := ypos1 - ypos2
	return dx*dx + dy*dy
}
