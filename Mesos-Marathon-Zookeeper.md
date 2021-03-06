# Install Mesos on Ubuntu 16.04

```
cat <<EOF >> /etc/apt/sources.list.d/mesosphere.list
deb http://repos.mesosphere.com/ubuntu xenial main
EOF

apt update
apt-get -y install mesos marathon  
```

## Configure Zookeeper (only for mesos-master)

```
cat <<EOF >> etc/zookeeper/conf/myid
1
EOF

cat <<EOF >> /etc/zookeeper/conf/zoo.cfg
server.1=`hostname`:2888:3888
EOF
```

## Configure Mesos Master

##### For multiple masters, put it as
##### zk://host1:2181,host2:2181,host3:2181/mesos

```
cat <<EOF >> /etc/mesos/zk
zk://`hostname`:2181/mesos
EOF

cat <<EOF >> /etc/mesos-master/quorum
1
EOF

echo 'MESOS_QUORUM=1' >> /etc/default/mesos-master

echo 'mesos-master IP' | sudo tee /etc/mesos-master/ip
cp /etc/mesos-master/ip /etc/mesos-master/hostname
```

## Configure Marathon on Mesos-master

```
mkdir -p /etc/marathon/conf
cp /etc/mesos-master/hostname /etc/marathon/conf
cp /etc/mesos/zk /etc/marathon/conf/master
cp /etc/marathon/conf/master /etc/marathon/conf/zk
sed -i 's/mesos/marathon/g' /etc/marathon/conf/zk
```

## Configure Mesos Slave

```
echo 'mesos-slave ip' | sudo tee /etc/mesos-slave/ip
sudo cp /etc/mesos-slave/ip /etc/mesos-slave/hostname

echo 'docker,mesos' > /etc/mesos-slave/containerizers
```

## Configure Docker

#### Install docker

```
docker login <url> --username=<username>
cd ~
tar czf docker.tar.gz .docker
cp docker.tar.gz /etc/mesos/
```

##### Now, Add the path to the gzipped login credentials to your Marathon app definition, like..

```
"uris": [
  "file:///etc/mesos/docker.tar.gz"
]
```

## Bring up Mesos-Master

```
echo manual | sudo tee /etc/init/mesos-slave.override
sudo service zookeeper start
#nohup sudo mesos-master --ip=<mesos-master-ip> --work_dir=/var/lib/mesos --hostname=<mesos-master-ip> >mesos-master.log 2>&1 &
sudo service mesos-master start
sudo service marathon start
```

## Bring up Mesos-Slave

```
echo manual | sudo tee /etc/init/mesos-master.override
echo manual | sudo tee /etc/init/zookeeper.override
sudo service zookeeper start
#nohup sudo mesos-slave --master=<mesos-master-ip>:5050 --log_dir=/var/log/mesos --work_dir=/var/lib/mesos --containerizers=mesos,docker --resources="ports(*):[8000-9000,31000-32000]" --ip=<mesos-slave-ip> >mesos-slave.log 2>&1 &
sudo service mesos-slave start
```

## To deploy an application

```
curl -X POST http://<mesos-master-ip>:8080/v2/apps -d @<application-deployment.json filename> -H "Content-type: application/json"
```

## FAQs

#### 1. On Mesos-UI (browser), to view Agent sandbox, add Agent hostname and IP to /etc/hosts of the viewing machine.
#### 2. When memory swap error, as below

##### Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.

```
# modify file - /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1"
GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
```

```
sudo update-grub && sudo reboot
```

##### To enable swap on DigitalOcean, refer - https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-16-04

#### 3. To check logs => /var/lib/mesos/meta/slave

#### 4. To setup a Mesos Cluster on Docker containers

<https://medium.com/@gargar454/deploy-a-mesos-cluster-with-7-commands-using-docker-57951e020586>

For multi-host Cluster setup - <https://github.com/sekka1/mesosphere-docker#multi-node-setup>

#### 4. After Mesos-DNS setup, to check nodes having a service installed
```
nslookup <service-name>.<framework>.<domain>
```