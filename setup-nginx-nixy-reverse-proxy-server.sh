#!/bin/bash
if [ "$#" -eq 0 ]; then
  echo "Usage: $@ mesos-master IP addresses" >&2
  exit 1
fi

# Change Timezone
rm /etc/localtime 
ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

sudo apt-get install -y nginx

cd /tmp

wget https://github.com/martensson/nixy/releases/download/v0.9.0/nixy_0.9.0_linux_amd64.tar.gz

tar -xvf nixy_0.9.0_linux_amd64.tar.gz

mv nixy_0.9.0_linux_amd64/ /opt/nixy/

cd -

marathonStr="marathon = ["
for var in "$@"
do
	marathonStr="$marathonStr \"http://$var:8080\","
done
marathonStr="${marathonStr::-1} ]"
sed "s~marathon.*~$marathonStr~g" nixy-template.toml >/opt/nixy/nixy.toml

cp nginx.tmpl /opt/nixy/.
cp /opt/nixy/nginx.tmpl /etc/nginx/.
systemctl start nginx
sh -c '/opt/nixy/nixy -f /opt/nixy/nixy.toml &> /var/log/nixy.log'