#!/bin/bash
function system_info {
       echo "### OS information ###"
       lsb_release -a

       echo
       echo "### Processor information ###"
       processor=`grep -wc "processor" /proc/cpuinfo`
       model=`grep -w "model name" /proc/cpuinfo  | awk -F: '{print $2}'`
       echo "Processor = $processor"
       echo "Model     = $model"

       echo
       echo "### Memory information ###"
       total=`grep -w "MemTotal" /proc/meminfo | awk '{print $2}'`
       free=`grep -w "MemFree" /proc/meminfo | awk '{print $2}'`
       echo "Total memory: $total kB"
       echo "Free memory : $free kB"
 }
pause 2
echo "Remove any previous version of Docker"
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt-get update
sudo apt autoclean
echo " removed any previous version of Docker if installed"
pause 2

echo "Installing Prerequisites for Docker"

sudo apt-get update && apt-get install apt-transport-https ca-certificates curl software-properties-common -y
sudo apt-get install gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "Adding APT Lists"
echo \
 "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo ## Update and Install
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo apt-get upgrade -y
pause 2
echo # Setting Docker Demon
# Setup daemon.
sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

function grpexists {
    if [ $(getent group docker) ]; then
      echo "group $1 exists."
    else
      echo sudo gpasswd -a $USER docker
    fi
}

sudo gpasswd -a $USER docker
echo # demon installed creacting docker service
sudo mkdir -p /etc/systemd/system/docker.service.d
pause 2
echo # install docker-compose
sudo systemctl status docker containerd
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
touch status.txt
sudo docker-compose --version >> status.txt
sudo docker -v >>status.txt
sudo usermod -aG docker jgrewal
sudo docker ps -a >>status.txt
sudo cat status.txt
pause 3
sudo rm status.txt

echo # Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl is-enabled docker
sudo systemctl is-enabled containerd
echo #docker installed and running
