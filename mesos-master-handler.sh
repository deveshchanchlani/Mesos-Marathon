#!/bin/sh
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 (start) or (stop)" >&2
  exit 1
fi

sudo service zookeeper $1
sudo service mesos-master $1
sudo service marathon $1