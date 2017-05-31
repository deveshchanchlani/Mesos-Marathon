#!/bin/sh
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 mesos-master IP address" >&2
  echo "Usage: $1 mesos-slave IP address" >&2
  exit 1
fi

#Change Timezone
rm /etc/localtime 
ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

#Install Java8 dependency
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java8-installer

#Install Docker
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
sudo apt-get -y update
apt-cache policy docker-engine
sudo apt-get install -y docker-engine
sudo usermod -aG docker $(whoami)

#Install Mesos & Marathon
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" | sudo tee /etc/apt/sources.list.d/mesosphere.list

sudo apt-get -y update

sudo apt-get install -y mesos

#Configure Zookeeper
cat <<EOF >> /etc/zookeeper/conf/zoo.cfg
server.1=$1:2888:3888
EOF

cat <<EOF > /etc/mesos/zk
zk://$1:2181/mesos
EOF

#Configure Mesos Slave
echo $2 | sudo tee /etc/mesos-slave/ip
sudo cp /etc/mesos-slave/ip /etc/mesos-slave/hostname

echo 'docker,mesos' > /etc/mesos-slave/containerizers

# Configure Docker

docker login hub.docker.com --username=deveshdocker
cd ~
tar czf docker.tar.gz .docker
cp docker.tar.gz /etc/mesos/

#Configure Swap Partition
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf

#Start Services
sudo service zookeeper start
sudo service mesos-slave start