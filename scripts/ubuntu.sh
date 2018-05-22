sudo apt-get update
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 6.11.0
node -e "console.log('Running Node.js ' + process.version)"
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install certbot 
sudo apt-get install git
sudo apt-get install libcairo2-dev libjpeg-turbo8-dev libgif-dev
sudo apt-get install gcc g++
git clone -b server https://github.com/foolmoron/Inlight2017.git
cd Inlight2017/
npm install
mkdir certs
sudo certbot certonly --standalone -w certs -d inlight.fool.games

echo "1. Change ports to 80/443"
echo "2. Change config.js secret/pass/host"