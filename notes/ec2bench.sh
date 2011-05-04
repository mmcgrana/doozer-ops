# setup ec2 creds and doozer key pair + security group as in ec2try.sh

# launch 6 64 bit instances in the doozer security group
ec2run ami-9043bff9 -t m1.large -g doozer -k doozer -n 6

# wait for the instances to come online
watch ec2din

# install and start dooozerd on the first instance
ssh -i doozer.pem ubuntu@$PUBLIC_IP_1
sudo -i
cd /opt
wget --no-check-certificate https://github.com/downloads/ha/doozerd/doozer-0.6-linux-amd64.tar.gz
tar xfz doozer-0.6-linux-amd64.tar.gz
rm doozer-0.6-linux-amd64.tar.gz
cd doozer-0.6
./doozerd -l $PRIVATE_IP_1:8046 -w 0.0.0.0:8047

# check it on the web
open http://$PUBLIC_IP_1:8047

# install doozer-ops on the test instance
ssh -i doozer.pem ubuntu@$PUBLIC_IP_0
sudo -i
add-apt-repository ppa:ubuntu-on-rails
apt-get update
apt-get install git-core g++ ruby ruby-dev rubygems irb ri rdoc rake
gem install bundler
export PATH=$PATH:/var/lib/gems/1.8/bin
cd /opt
git clone https://mmcgrana@github.com/mmcgrana/doozer-ops.git
cd doozer-ops
bundle install

# run benchmarks against the single node from the test instance
export DOOZER_URI=doozer:?ca=$PRIVATE_IP_1:8046
bin/write 1000 5 --verbose
bin/read 1000 5 --verbose
bin/sink --verbose

# on the first doozer instance,
# indicate that we expect four more nodes to join this cluster as consensors
cd /opt/doozer-0.6
for N in 1 2 3 4
do
  echo -n | ./doozer -a $PRIVATE_IP_1:8046 add /ctl/cal/$N
done

# join the other 4 nodes to the cluster
ssh -i doozer.pem ubuntu@$PUBLIC_IP_N
sudo -i
cd /opt
wget --no-check-certificate https://github.com/downloads/ha/doozerd/doozer-0.6-linux-amd64.tar.gz
tar xfz doozer-0.6-linux-amd64.tar.gz
rm doozer-0.6-linux-amd64.tar.gz
cd doozer-0.6
./doozerd -a $PRIVATE_IP_1:8046 -l $PRIVATE_IP_N:8046 -w 0.0.0.0:8047

# wait until all doozers have fully joined

# run benchmarks against the 5 node cluster
bin/write 1000 5 --verbose
bin/read 1000 5 --verbose


