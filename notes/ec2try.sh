# provide aws credentials for command line tools
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export EC2_PRIVATE_KEY=...
export EC2_CERT=...

# provide aws account id for our own use
export AWS_ACCOUNT_ID=...

# create key pair
ec2addkey doozer | tail -n +2 > doozer.pem
chmod 600 doozer.pem

# create security group
ec2addgrp doozer -d "Doozer distributed datastore"

# enable ssh access to the group
ec2auth doozer -P tcp -p 22

# enable udp traffic among the nodes on the doozer port
ec2auth doozer -P udp -p 8046 -o doozer -u $AWS_ACCOUNT_ID

# enable tcp traffic among the instances and from external users on the doozer port
ec2auth doozer -P tcp -p 8046

# enable tcp traffic from external users for web access
ec2auth doozer -P tcp -p 8047

# launch 4 64 bit instances in the security group
ec2run ami-9043bff9 -t m1.large -g doozer -k doozer -n 4

# wait for the instances to come online
watch ec2din

# ssh to the first instance
ssh -i doozer.pem ubuntu@$PUBLIC_IP_1
sudo -i

# verify that you can receive tcp traffic from outside clients
# on the instance
nc -l -p 8046

# on your machine
echo "test tcp" | nc $PUBLIC_IP_1 8046

# ssh to the second instance
ssh -i doozer.pem ubuntu@$PUBLIC_IP_1
sudo -i

# verify that you can send udp traffic among the instances
# on the first instance
nc -u -l 8046

# on the second instance
echo "test udp" | nc -u $PRIVATE_IP_1 8046

# install and start dooozerd on the first instance
cd /opt
wget --no-check-certificate https://github.com/downloads/ha/doozerd/doozer-0.6-linux-amd64.tar.gz
tar xfz doozer-0.6-linux-amd64.tar.gz
rm doozer-0.6-linux-amd64.tar.gz
cd doozer-0.6
./doozerd -l $PRIVATE_IP_1:8046 -w 0.0.0.0:8047

# indicate that we expect two more nodes to join this cluster as consensors
echo -n | ./doozer -a $PRIVATE_IP_1:8046 add /ctl/cal/1
echo -n | ./doozer -a $PRIVATE_IP_1:8046 add /ctl/cal/2

# join the other 3 nodes to the cluster
# for each N in 2,3,4
ssh -i doozer.pem ubuntu@$PUBLIC_IP_N
sudo -i
cd /opt
wget --no-check-certificate https://github.com/downloads/ha/doozerd/doozer-0.6-linux-amd64.tar.gz
tar xfz doozer-0.6-linux-amd64.tar.gz
rm doozer-0.6-linux-amd64.tar.gz
cd doozer-0.6
./doozerd -a $PRIVATE_IP_1:8046 -l $PRIVATE_IP_N:8046 -w 0.0.0.0:8047

# check the web interface for one of the public ips
open http://$PUBLIC_IP_4:8057
