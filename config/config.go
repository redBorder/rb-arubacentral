package config

import (
	"io"
	"os"

	"gopkg.in/yaml.v2"
)

type Config struct {
	ArubaConfig struct {
		Endpoint     string `yaml:"endpoint"`
		Username     string `yaml:"username"`
		Password     string `yaml:"password"`
		ClientID     string `yaml:"client_id"`
		ClientSecret string `yaml:"client_secret"`
		CustomerID   string `yaml:"customer_id"`
	} `yaml:"aruba"`
	ZooKeeperConfig struct {
		Servers []string `yaml:"servers"`
	} `yaml:"zookeeper"`
	Service struct {
		SleepTime int `yaml:"sleep_time"`
	} `yaml:"service"`
}

func ReadConfigFile(filename string) (Config, error) {
	var config Config

	file, err := os.Open(filename)
	if err != nil {
		return config, err
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		return config, err
	}

	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return config, err
	}

	return config, nil
}
