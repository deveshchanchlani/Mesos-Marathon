#!/bin/sh

# DO create 3 instances
echo "############# creating master node"
MASTER_ID=$(doctl compute droplet create mesos-master-1 --size 512mb --image ubuntu-16-04-x64 --region blr1 --ssh-keys b2:d6:0e:9f:75:78:c1:8e:65:b5:b9:f6:8d:44:fa:b2 --no-header | tr -s ' ' | cut -d ' '  -f 1)
echo "############# Master Node Id = ${MASTER_ID}"

MASTER_IP=$(doctl compute droplet get ${MASTER_ID} --format PublicIPv4 --no-header)
echo "############# Master Node IP = ${MASTER_IP}"

echo "############# creating slave node"
SLAVE_ID=$(doctl compute droplet create mesos-slave-1 --size 512mb --image ubuntu-16-04-x64 --region blr1 --ssh-keys b2:d6:0e:9f:75:78:c1:8e:65:b5:b9:f6:8d:44:fa:b2 --no-header | tr -s ' ' | cut -d ' '  -f 1)
echo "############# Slave Node Id = ${SLAVE_ID}"

SLAVE_IP=$(doctl compute droplet get ${SLAVE_ID} --format PublicIPv4 --no-header)
echo "############# Slave Node IP = ${SLAVE_IP}"

echo "############# creating proxy node"
PROXY_ID=$(doctl compute droplet create nginx-proxy-1 --size 512mb --image ubuntu-16-04-x64 --region blr1 --ssh-keys b2:d6:0e:9f:75:78:c1:8e:65:b5:b9:f6:8d:44:fa:b2 --no-header | tr -s ' ' | cut -d ' '  -f 1)
echo "############# Proxy Node Id = ${PROXY_ID}"

PROXY_IP=$(doctl compute droplet get ${PROXY_ID} --format PublicIPv4 --no-header)
echo "############# Proxy Node IP = ${PROXY_IP}"

echo "############# scp to master and trigger setup"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mesos-master-handler.sh root@${MASTER_IP}:/root/.
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null setup-mesos-master.sh root@${MASTER_IP}:/root/.
ssh root@${MASTER_IP} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "cd /root; sudo sh ./setup-mesos-master.sh ${MASTER_IP}"
echo "############# Master Node Setup Complete"

echo "############# scp to slave and trigger setup"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null setup-mesos-slave.sh root@${SLAVE_IP}:/root/.
ssh root@${SLAVE_IP} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "cd /root; sudo sh ./setup-mesos-slave.sh ${MASTER_IP} ${SLAVE_IP}"
echo "############# Slave Node Setup Complete"

echo "############# scp to proxy and trigger setup"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nginx.tmpl root@${PROXY_IP}:/root/.
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nixy-template.toml root@${PROXY_IP}:/root/.
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null setup-nginx-nixy-reverse-proxy-server.sh root@${PROXY_IP}:/root/.
ssh root@${PROXY_IP} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "chmod a+x ./setup-nginx-nixy-reverse-proxy-server.sh; ./setup-nginx-nixy-reverse-proxy-server.sh ${MASTER_IP}"
echo "############# Proxy Node Setup Complete"
