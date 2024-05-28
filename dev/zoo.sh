#!/bin/bash

path=$(dirname $0)

cd $path

sudo docker-compose up -d

echo "ZooKeeper is running. Press Ctrl+C to stop."

while true; do
  sleep 1
done
