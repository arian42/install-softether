#!/bin/bash
RED='\033[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
NC='\033[0m'

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
	printf "\n${RED}This script needs to be run with bash, not sh${NC}"
	exit
fi
# Check for root
if [[ "$EUID" -ne 0 ]]; then
	printf "\n${RED}You need to run this as root${NC}"
	exit
fi

print_info () {
	if $?; then
		printf "\n${GREEN}Done.${NC}"
	else
		printf "\n${RED}Faild.${NC}\nCheck your internet connection."
	fi
}

printf "\n${YELLOW}Updating system... ${NC}"
yum update -y
print_info

printf "\n${YELLOW}Installing development tools for compiling softether vpn.${NC}"
if yum groupinstall "development tools" -y; then
	printf "\n${GREEN}Done.${NC}"
else
	printf "\n${RED}Faild.${NC}\nCheck your internet connection."
fi
printf "\n${YELLOW}Updating system...${NC}"
if yum install wget -y; then
	printf "\n${GREEN}Done.${NC}"
else
	printf "\n${RED}Faild.${NC}\nCheck your internet connection."
fi

printf "\n${YELLOW}Downloading softether from Github...${NC}"
# Download softether vpn
wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.28-9669-beta/softether-vpnserver-v4.28-9669-beta-2018.09.11-linux-x64-64bit.tar.gz

printf "\n${YELLOW}extracting softether VPN...${NC}"
# extract it
tar -xzf softether-vpnserver-v4.28-9669-beta-2018.09.11-linux-x64-64bit.tar.gz

# remove compress file
rm -rf softether-vpnserver-v4.28-9669-beta-2018.09.11-linux-x64-64bit.tar.gz
cd ./vpnserver


# also install dev-tools
#yum groupinstall "development tools" -y
printf "\n${YELLOW}Compiling softether VPN...${NC}"
# compile it
make
cd ..

# install it in /usr/local
mv vpnserver/ /usr/local

printf "\n${YELLOW}Creating systemd service...${NC}"
# create vpnserver service
printf "[Unit]\nDescription=SoftEther vpn server\nAfter=local-fs.target network.target\n\n[Service]\nWorkingDirectory=/usr/local/vpnserver\nType=forking\nRestart=always\n\nExecStart=/usr/local/vpnserver/vpnserver start\nExecStop=/usr/local/vpnserver/vpnserver stop\n\n[Install]\nWantedBy=multi-user.target">/etc/systemd/system/vpn.service

printf "\n${YELLOW}updating services...${NC}"
systemctl daemon-reload

printf "\n${YELLOW}Runing vpnserver service...${NC}"
systemctl enable vpn
systemctl start vpn
systemctl status vpn
