package main

import (
	"flag"
	"log"
	"os"
	"time"

	config "redborder.com/rb-arubacentral/config"
	lib "redborder.com/rb-arubacentral/lib"
	arubacentral "redborder.com/rb-arubacentral/rest"
)

func connectToZooKeeper(GoAruba *arubacentral.ArubaClient, conf config.Config) {
	client, err := lib.NewZookeeperClient(conf.ZooKeeperConfig.Servers)
	if err != nil {
		log.Fatalf("Failed to connect to Zookeeper: %v", err)
	}
	defer client.Close()

	for {
		if !client.IsLocked() {
			client.Lock()
			// Main fetch loop here
			client.ReleaseLock()
		}
		log.Println("Sleeping for", conf.Service.SleepTime, "seconds")
		time.Sleep(time.Duration(conf.Service.SleepTime) * time.Second)
	}
}

func readConfig() config.Config {
	configFile := flag.String("c", "", "Path to YAML config file")
	showHelp := flag.Bool("h", false, "Show usage information")

	flag.Parse()

	if *showHelp || flag.NFlag() == 0 {
		flag.Usage()
		os.Exit(1)
	}

	conf, err := config.ReadConfigFile(*configFile)
	if err != nil {
		log.Fatalf("Error reading config file: %v", err)
	}

	return conf
}

func main() {
	config := readConfig()
	GoAruba := arubacentral.NewArubaClient(
		config.ArubaConfig.Endpoint,
		config.ArubaConfig.Username,
		config.ArubaConfig.Password,
		config.ArubaConfig.ClientID,
		config.ArubaConfig.ClientSecret,
		config.ArubaConfig.CustomerID,
	)
	connectToZooKeeper(GoAruba, config)
}
