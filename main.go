package main

import (
	"fmt"
	"log"
	"time"

	lib "redborder.com/rb-arubacentral/lib"
	arubacentral "redborder.com/rb-arubacentral/rest"
)

func connectToZooKeeper(GoAruba *arubacentral.ArubaClient) {
	servers := []string{"127.0.0.1:2181"}

	client, err := lib.NewZookeeperClient(servers)
	if err != nil {
		log.Fatalf("Failed to connect to Zookeeper: %v", err)
	}
	defer client.Close()

	for {
		isLocked := client.IsLocked()
		if !isLocked {
			log.Println("Locking...")
			client.Lock()
			time.Sleep(5 * time.Second)
			client.ReleaseLock()
		} else {
			log.Println("A lock is already in place. Waiting...")
			time.Sleep(5 * time.Second)
		}
	}
}

func main() {
	GoAruba := arubacentral.NewArubaClient(
		"",
		"",
		"",
		"",
		"",
		"",
	)

	connectToZooKeeper(GoAruba)

	resp, err := GoAruba.Get("/visualrf_api/v1/campus")

	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Println("Response:", string(resp))
}
