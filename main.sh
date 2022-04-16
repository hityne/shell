#!/bin/bash

# 定义颜色变量, 还记得吧, \033、\e和\E是等价的
RED='\E[1;31m'       # 红
GREEN='\E[1;32m'    # 绿
YELLOW='\E[1;33m'    # 黄
BLUE='\E[1;34m'     # 蓝
PINK='\E[1;35m'     # 粉红
RES='\E[0m'          # 清除颜色

[[ $(id -u) != 0 ]] && echo -e " 请使用 ${YELLOW}root ${RES}用户运行 ${RED}~(^_^) ${RES}" && exit 1

function GetIp() {
  MAINIP=$(ip route get 1 | awk -F 'src ' '{print $2}' | awk '{print $1}')
  GATEWAYIP=$(ip route | grep default | awk '{print $3}')
  SUBNET=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}' | head -1 | awk -F '/' '{print $2}')
  value=$(( 0xffffffff ^ ((1 << (32 - $SUBNET)) - 1) ))
  NETMASK="$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
  URIP=$(curl -s https://ipinfo.io/ip)
}
function install_bbr() {
	local test1=$(sed -n '/net.ipv4.tcp_congestion_control/p' /etc/sysctl.conf)
	local test2=$(sed -n '/net.core.default_qdisc/p' /etc/sysctl.conf)
	if [[ $test1 == "net.ipv4.tcp_congestion_control = bbr" && $test2 == "net.core.default_qdisc = fq" ]]; then
		echo
		echo -e "${GREEN} BBR 已经启用啦...无需再安装${RES}"
		echo
	else
		[[ ! $enable_bbr ]] && wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh && chmod 755 /opt/bbr.sh && /opt/bbr.sh
	fi
}

GetIp

# ip_info=$(curl ip.gs/json)
# ip_ip=$(echo $ip_info | jq .ip)
# ip_country=$(echo $ip_info | jq .country)
# ip_region=$(echo $ip_info | jq .region_name)
# ip_city=$(echo $ip_info | jq .city)

which wget >/dev/null 2>&1
if [ $? -ne 0 ]; then
	apt update
	apt install -y wget
fi
which curl >/dev/null 2>&1
if [ $? -ne 0 ]; then
	apt update
	apt install -y curl
fi

clear
echo ""
echo "==========================================================================="
echo -e "${RED}Main page:${RES}"
echo -e "${GREEN}Your IP: $MAINIP${RES}"
echo ""
echo -e "  ${YELLOW}1.DD system${RES}                                   ${YELLOW}2.Install bbr${RES}"
echo ""
echo -e "  ${YELLOW}3.Install bt Panel${RES}                            ${YELLOW}4.Install v2ray${RES}"
echo ""
echo -e "  ${YELLOW}5.Modify SSH Port (for defaut port 22)${RES}        ${YELLOW}6.Unixbech一键跑分${RES}"
echo ""
echo -e "  ${YELLOW}7.Install docker and docker-compose${RES}           ${YELLOW}8.Install docker filerun${RES}" 
echo ""
echo -e "  ${YELLOW}9.Set localtime to China zone${RES}                 ${YELLOW}10.VPS info${RES}"
echo ""
echo -e "  ${YELLOW}11.Test speed (bench.sh)${RES}                      ${YELLOW}12.Install python3${RES}"
echo ""
echo -e "  ${YELLOW}13.Install serverstatus${RES}                       ${YELLOW}14.Git Commands cheklist${RES}"
echo ""
echo -e "  ${YELLOW}15.Install essentials for Debian 10${RES}           ${YELLOW}16.Install docker aria2 & ariang${RES}"
echo ""
echo -e "${RED}Written by Richard, updated on 2022/04/17${RES}"
echo "==========================================================================="

echo ""
read -p "Please input the number you choose: " main_no


if [ "$main_no" = "1" ]; then
	wget https://raw.githubusercontent.com/hityne/ssh/master/mydd.sh && chmod a+x mydd.sh && bash mydd.sh
elif [ "$main_no" = "2" ]; then
	install_bbr
elif [ "$main_no" = "3" ]; then
	wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && bash install.sh
	echo ""
	read -p "Do you want to degrade to version 7.7  [y or n] " if_degrade
	if [ "$if_degrade" = "y" ]; then
		wget http://download.bt.cn/install/update/LinuxPanel-7.7.0.zip
		unzip LinuxPanel-*
		cd panel
		bash update.sh
		cd .. && rm -f LinuxPanel-*.zip && rm -rf panel
		rm -f /www/server/panel/data/bind.pl
		echo "BT 7.7 has been installed successfully."
		echo ""
		read -p "Do you want to hack to happy 7.7  [y or n] " if_hack
		if [ "$if_hack" = "y" ]; then
			curl http://download.moetas.com/install/update6.sh|bash
		fi
	else
		echo "New BT version has been installed successfully."
	fi
	
	echo ""

elif [ "$main_no" = "4" ]; then
	wget -O v2ray.sh https://raw.githubusercontent.com/hityne/others/main/v2ray.sh && chmod a+x v2ray.sh && bash v2ray.sh
elif [ "$main_no" = "5" ]; then
	echo ""
	echo "Please input the ssh port you want to use"
	read -p "Please input the port you select for SSH login: " ssh_port
	echo "=========================================="
	echo SSH port="$ssh_port"
	echo "==========================================="
	echo ""
	#Break here
	read -n 1 -p "Press any key to continue..."
	old_port=$(sed -n '/^Port/'p /etc/ssh/sshd_config)
	sed -i 's/'$old_port'/Port '$ssh_port'/g' /etc/ssh/sshd_config
	systemctl restart ssh
	echo""
	echo "Service sshd has been restarted. Please use the new SSH port to login."
elif [ "$main_no" = "6" ]; then
	wget --no-check-certificate https://github.com/teddysun/across/raw/master/unixbench.sh && chmod +x unixbench.sh && ./unixbench.sh
elif [ "$main_no" = "7" ]; then
	read -p "do you want to install docker service? [y (default) or n] " bbb
	if [ "$bbb" != "n" ]; then
		curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
		systemctl enable docker
		systemctl start docker
		echo ""
		echo "docker server is working."
		echo ""
	fi
	read -p "do you want to install docker-compose? [y (default) or n] " aaa
	if [ "$aaa" != "n" ]; then
		curl -L https://github.com/docker/compose/releases/download/1.17.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
		chmod +x /usr/local/bin/docker-compose
		echo ""
		docker-compose --version
		echo "docker-compose has been installed."
		echo ""
	fi
elif [ "$main_no" = "8" ]; then
	echo "安装docker filerun"
	wget --no-check-certificate https://raw.githubusercontent.com/hityne/ssh/master/filerun_docker_install.sh && bash filerun_docker_install.sh && rm filerun_docker_install.sh
	
elif [ "$main_no" = "9" ]; then
	rm -rf /etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	date -R
elif [ "$main_no" = "10" ]; then
	wget https://github.com/hityne/ssh/raw/master/dmytest.sh && chmod +x dmytest.sh && bash dmytest.sh && rm -f dmytest.sh
	
elif [ "$main_no" = "11" ]; then	
	wget -qO- bench.sh | bash

elif [ "$main_no" = "12" ]; then	
	wget https://github.com/hityne/ssh/raw/master/install_python3_on_debian10.sh && chmod +x install_python3_on_debian10.sh && bash install_python3_on_debian10.sh && rm install_python3_on_debian10.sh

elif [ "$main_no" = "13" ]; then	

	read -p "do you want to install ServerStatus server[0] or client[1]? [0 (default) or 1] " ss_option
	if [ "$ss_option" != "1" ]; then

		if systemctl is-active docker &>/dev/null ;then
			echo "docker已经启动"
		else
			echo "docker未启动"
			echo "请先启动docker服务"
			echo ""
			exit 0
		fi

		mkdir /serverstatus
		wget --no-check-certificate -qO /serverstatus/serverstatus-config.json https://raw.githubusercontent.com/cppla/ServerStatus/master/server/config.json && mkdir /serverstatus/serverstatus-monthtraffic    
		docker run -d --restart=always --name=serverstatus -v /serverstatus/serverstatus-config.json:/ServerStatus/server/config.json -v /serverstatus/serverstatus-monthtraffic:/usr/share/nginx/html/json -p 35600:80 -p 35601:35601 cppla/serverstatus:latest
		echo "Pls visit http://yourip:35600 to check if it works."
		echo ""
	else
		mkdir /serverclient
		wget --no-check-certificate -qO /serverclient/client-linux.py 'https://raw.githubusercontent.com/cppla/ServerStatus/master/clients/client-linux.py' 
		echo "Please input SERVER ip and USER id(sxx):"
		read -p "Please input SERVER ip: " SERVER_ip
		read -p "Please input USER id: " USER_id
		echo "=========================================="
		echo SERVER ip="$SERVER_ip"
		echo USER id="$USER_id"
		echo "==========================================="
		which python >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "runing python ..."
			nohup python /serverclient/client-linux.py SERVER=$SERVER_ip USER=$USER_id >/dev/null 2>&1 &
			ps -e | grep python
		else
			echo "runing python3 ..."
			nohup python3 /serverclient/client-linux.py SERVER=$SERVER_ip USER=$USER_id >/dev/null 2>&1 &
			ps -e | grep python3
		fi
		
		

	fi
elif [ "$main_no" = "14" ]; then	
	echo "COMING SOON"

elif [ "$main_no" = "15" ]; then	
	echo "安装debian10 必要组件"
	wget --no-check-certificate https://raw.githubusercontent.com/hityne/ssh/master/mydebian.sh && bash mydebian.sh && rm mydebian.sh

elif [ "$main_no" = "16" ]; then	
	echo "安装docker aria2 & ariang "
	wget --no-check-certificate https://raw.githubusercontent.com/hityne/ssh/master/aria2_docker_install.sh && bash aria2_docker_install.sh && rm aria2_docker_install.sh

else
exit 0

fi
