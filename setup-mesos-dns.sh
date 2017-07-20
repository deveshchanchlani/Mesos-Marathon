#!/bin/sh

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 mesos-master IP address." >&2
  echo "Usage: $1 mesos-dns IP address." >&2
  exit 1
fi

mkdir /usr/local/mesos-dns/
wget -O /usr/local/mesos-dns/mesos-dns https://github.com/mesosphere/mesos-dns/releases/download/v0.6.0/mesos-dns-v0.6.0-linux-amd64
chmod a+x /usr/local/mesos-dns/mesos-dns

sed -i "s/master-ip/$1/g" mesos-dns-config.json
mv mesos-dns-config.json /usr/local/mesos-dns/.

sudo /usr/local/mesos-dns/mesos-dns -config=/usr/local/mesos-dns/mesos-dns-config.json

sudo sed -i "1s/^/nameserver $2\n /" /etc/resolv.conf
