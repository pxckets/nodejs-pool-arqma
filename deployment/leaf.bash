#!/bin/bash
echo "This assumes that you are doing a green-field install.  If you're not, please exit in the next 15 seconds."
sleep 15
echo "Continuing install, this will prompt you for your password if you're not already running as root and you didn't enable passwordless sudo.  Please do not run me as root!"
if [[ `whoami` == "root" ]]; then
    echo "You ran me as root! Do not run me as root!"
    exit 1
fi
CURUSER=$(whoami)
sudo timedatectl set-timezone Etc/UTC
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install git python-virtualenv python3-virtualenv curl ntp build-essential screen cmake pkg-config libboost-all-dev libevent-dev libunbound-dev libminiupnpc-dev libunwind8-dev liblzma-dev libldns-dev libexpat1-dev libgtest-dev libzmq3-dev
cd ~
git clone https://github.com/oscillate-project/nodejs-pool-oscillate.git  # Change this depending on how the deployment goes.
cd /usr/src/gtest
sudo cmake .
sudo make
sudo mv libg* /usr/lib/
cd ~
sudo systemctl enable ntp
cd /usr/local/src
sudo git clone https://github.com/oscillate_project/OSLV2.git
cd oscillate
sudo make -j$(nproc)
sudo cp ~/nodejs-pool/deployment/oscillate.service /lib/systemd/system/
sudo useradd -m oscillatedaemon -d /home/oscillatedaemon
sudo systemctl daemon-reload
sudo systemctl enable oscillate
sudo systemctl start oscillate
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
source ~/.nvm/nvm.sh
nvm install v8.9.3
cd ~/nodejs-pool-oscillate
npm install
npm install -g pm2
openssl req -subj "/C=IT/ST=Pool/L=Daemon/O=Mining Pool/CN=mining.pool" -newkey rsa:2048 -nodes -keyout cert.key -x509 -out cert.pem -days 36500
cd ~
sudo env PATH=$PATH:`pwd`/.nvm/versions/node/v8.9.3/bin `pwd`/.nvm/versions/node/v8.9.3/lib/node_modules/pm2/bin/pm2 startup systemd -u $CURUSER --hp `pwd`
sudo chown -R $CURUSER. ~/.pm2
echo "Installing pm2-logrotate in the background!"
pm2 install pm2-logrotate &
echo "You're setup with a leaf node!  Congrats"
