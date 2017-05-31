#!/bin/sh
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 mesos-master IP address" >&2
  exit 1
fi

#Change Timezone
rm /etc/localtime 
ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

#Install Java8 dependency
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java8-installer

#Install Mesos & Marathon
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" | sudo tee /etc/apt/sources.list.d/mesosphere.list

sudo apt-get -y update

sudo apt-get install -y mesos marathon

#Configure Zookeeper
cat <<EOF > /etc/zookeeper/conf/myid
1
EOF

cat <<EOF >> /etc/zookeeper/conf/zoo.cfg
server.1=$1:2888:3888
EOF

cat <<EOF > /etc/mesos/zk
zk://$1:2181/mesos
EOF

#Configure Mesos Master
cat <<EOF > /etc/mesos-master/quorum
1
EOF

echo 'MESOS_QUORUM=1' >> /etc/default/mesos-master

echo $1 | sudo tee /etc/mesos-master/ip
cp /etc/mesos-master/ip /etc/mesos-master/hostname

#Configure Marathon
mkdir -p /etc/marathon/conf
cp /etc/mesos-master/hostname /etc/marathon/conf
cp /etc/mesos/zk /etc/marathon/conf/master
cp /etc/marathon/conf/master /etc/marathon/conf/zk
sed -i 's/mesos/marathon/g' /etc/marathon/conf/zk

#Start Services
sh ./mesos-master-handler.sh start
