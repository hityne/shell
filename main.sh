#!/bin/bash

# 定义颜色变量, 还记得吧, \033、\e和\E是等价的
RED='\E[1;31m'       # 红
GREEN='\E[1;32m'    # 绿
YELLOW='\E[1;33m'    # 黄
BLUE='\E[1;34m'     # 蓝
PINK='\E[1;35m'     # 粉红
RES='\E[0m'          # 清除颜色

# 在文件开头添加临时目录定义
TEMP_DIR="/tmp/vps_script"

# 添加清理函数
function cleanup_temp() {
    rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"
}

# 在开始处调用清理
cleanup_temp

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
    local bbr_script="${TEMP_DIR}/bbr.sh"
    local test1=$(sed -n '/net.ipv4.tcp_congestion_control/p' /etc/sysctl.conf)
    local test2=$(sed -n '/net.core.default_qdisc/p' /etc/sysctl.conf)
    if [[ $test1 == "net.ipv4.tcp_congestion_control = bbr" && $test2 == "net.core.default_qdisc = fq" ]]; then
        echo -e "${GREEN} BBR 已经启用啦...无需再安装${RES}"
    else
        [[ ! $enable_bbr ]] && wget --no-check-certificate -O "${bbr_script}" https://github.com/teddysun/across/raw/master/bbr.sh && chmod 755 "${bbr_script}" && "${bbr_script}"
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

# 添加菜单分类和提示信息的常量
readonly MENU_SYSTEM="系统相关"
readonly MENU_NETWORK="网络相关"
readonly MENU_DOCKER="Docker相关"
readonly MENU_TOOLS="工具相关"

# 优化菜单显示函数
function show_menu() {
    clear
    echo ""
    echo "==========================================================================="
    echo -e "${RED}VPS管理面板${RES}"
    echo -e "${GREEN}当前IP: $MAINIP${RES}"
    echo ""
    echo -e "${BLUE}${MENU_SYSTEM}:${RES}"
    echo -e "  ${YELLOW}1. 安装 Debian 12${RES}                         ${YELLOW}2. 安装 BBR${RES}"
    echo -e "  ${YELLOW}3. 安装宝塔面板${RES}                           ${YELLOW}4. 修改 SSH 端口${RES}"
    echo -e "  ${YELLOW}5. 设置中国时区${RES}                           ${YELLOW}6. 安装 Debian 必备组件${RES}"
    echo ""
    echo -e "${BLUE}${MENU_NETWORK}:${RES}"
    echo -e "  ${YELLOW}7. 安装 V2ray${RES}                             ${YELLOW}8. 安装 X-UI${RES}"
    echo -e "  ${YELLOW}9. 安装 ServerStatus${RES}                      ${YELLOW}10. 安装 TinyProxy${RES}"
    echo -e "  ${YELLOW}11. 下载 FRP 包${RES}"
    echo ""
    echo -e "${BLUE}${MENU_DOCKER}:${RES}"
    echo -e "  ${YELLOW}12. 安装 Docker/Compose${RES}                   ${YELLOW}13. 安装 Docker Filerun${RES}"
    echo -e "  ${YELLOW}14. 安装 Docker Aria2${RES}"
    echo ""
    echo -e "${BLUE}${MENU_TOOLS}:${RES}"
    echo -e "  ${YELLOW}15. UnixBench 跑分${RES}                        ${YELLOW}16. 测试网速${RES}"
    echo -e "  ${YELLOW}17. 查看 VPS 信息${RES}                         ${YELLOW}18. 安装 Python3${RES}"
    echo ""
    echo -e "${RED}作者: Richard    更新时间: 2025/01/25${RES}"
    echo "==========================================================================="
    echo ""
}

# 优化用户输入提示
function read_user_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    local options=$4
    
    if [ -n "$options" ]; then
        echo "可选项: $options"
    fi
    
    read -p "$prompt [$default]: " input
    if [ -z "$input" ]; then
        input=$default
    fi
    eval $var_name=\$input
}

# 在主菜单选择部分替换if-elif结构
function handle_menu() {
    case "$1" in
        1) install_debian12 ;;
        2) install_bbr ;;
        3) install_bt_panel ;;
        4) modify_ssh_port ;;
        5) set_localtime_to_china_zone ;;
        6) install_debian_essentials ;;
        7) install_v2ray ;;
        8) install_xui ;;
        9) install_serverstatus ;;
        10) install_tinyproxy ;;
        11) download_frp ;;
        12) install_docker_and_docker_compose ;;
        13) install_docker_filerun ;;
        14) install_docker_aria2 ;;
        15) unixbench_score ;;
        16) test_speed ;;
        17) vps_info ;;
        18) install_python3 ;;
        *) 
            echo "Invalid option"
            exit 1
            ;;
    esac
}

function install_debian12() {
    local region_options="1) 中国大陆  2) 其他地区"
    read_user_input "请选择您的地区" "2" "region" "$region_options"
    
    local reinstall_script="${TEMP_DIR}/reinstall.sh"
    if [ "$region" = "1" ]; then
        curl -o "${reinstall_script}" https://www.ghproxy.cc/https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh || wget -O "${reinstall_script}" $_
    else
        curl -o "${reinstall_script}" https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh || wget -O "${reinstall_script}" $_
    fi
    bash "${reinstall_script}" debian 12
}

function install_bt_panel() {
    local install_script="${TEMP_DIR}/install.sh"
    local panel_zip="${TEMP_DIR}/LinuxPanel-7.7.0.zip"
    
    local panel_options="y) 安装国际版(aapanel)  n) 安装中文版(默认)"
    read_user_input "请选择宝塔面板版本" "n" "panel_version" "$panel_options"
    
    if [ "$panel_version" = "y" ]; then
        echo "正在安装国际版面板..."
        wget -O "${install_script}" http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash "${install_script}"
    else
        echo "正在安装中文版面板..."
        wget -O "${install_script}" http://download.bt.cn/install/install-ubuntu_6.0.sh && bash "${install_script}"
        
        local version_options="y) 降级到7.7版本  n) 保持最新版(默认)"
        read_user_input "是否需要降级面板版本" "n" "downgrade_version" "$version_options"
        
        if [ "$downgrade_version" = "y" ]; then
            echo "正在降级到7.7版本..."
            wget --no-check-certificate -O "${panel_zip}" https://github.com/hityne/ssh/raw/master/LinuxPanel-7.7.0.zip
            cd "${TEMP_DIR}"
            unzip "${panel_zip}"
            cd panel
            bash update.sh
            cd - > /dev/null
            rm -f /www/server/panel/data/bind.pl
            echo "宝塔面板已降级到7.7版本"
            
            local crack_options="y) 破解面板  n) 保持原样(默认)"
            read_user_input "是否破解面板" "n" "crack_panel" "$crack_options"
            if [ "$crack_panel" = "y" ]; then
                echo "正在破解面板..."
                curl http://download.moetas.com/install/update6.sh|bash
            fi
        else
            echo "保持最新版本安装完成"
        fi
    fi
}

function install_v2ray() {
    local v2ray_script="${TEMP_DIR}/v2ray.sh"
    wget --no-check-certificate -O "${v2ray_script}" https://raw.githubusercontent.com/hityne/others/main/v2ray.sh
    chmod a+x "${v2ray_script}"
    bash "${v2ray_script}"
}

function install_serverstatus() {
    local install_options="0) 安装服务端  1) 安装客户端"
    read_user_input "请选择安装类型" "0" "install_type" "$install_options"
    
    if [ "$install_type" != "1" ]; then
        install_serverstatus_server
    else
        install_serverstatus_client
    fi
}

function install_serverstatus_server() {
    echo "开始安装ServerStatus服务端..."
    
    # 检查Docker是否运行
    if ! systemctl is-active docker &>/dev/null; then
        echo "错误: Docker服务未启动"
        read_user_input "是否先安装Docker？(y/n)" "y" "install_docker_first"
        if [ "$install_docker_first" = "y" ]; then
            install_docker_and_docker_compose
        else
            echo "取消安装"
            return 1
        fi
    fi

    # 创建配置目录
    local config_dir="/serverstatus"
    mkdir -p "${config_dir}"
    
    # 下载配置文件
    echo "下载ServerStatus配置文件..."
    wget --no-check-certificate -qO "${config_dir}/serverstatus-config.json" \
        https://raw.githubusercontent.com/cppla/ServerStatus/master/server/config.json
    
    # 创建流量统计目录
    mkdir -p "${config_dir}/serverstatus-monthtraffic"
    
    echo "启动ServerStatus Docker容器..."
    docker run -d --restart=always --name=serverstatus \
        -v "${config_dir}/serverstatus-config.json:/ServerStatus/server/config.json" \
        -v "${config_dir}/serverstatus-monthtraffic:/usr/share/nginx/html/json" \
        -p 35600:80 -p 35601:35601 \
        cppla/serverstatus:latest
    
    if [ $? -eq 0 ]; then
        echo "ServerStatus服务端安装成功！"
        echo "请访问 http://${MAINIP}:35600 检查服务是否正常运行"
        echo "服务端口: "
        echo "  - Web界面: 35600"
        echo "  - 客户端通信: 35601"
    else
        echo "错误: ServerStatus服务端安装失败"
        return 1
    fi
}

function install_serverstatus_client() {
    local client_script="${TEMP_DIR}/client-linux.py"
    mkdir -p /serverclient
    wget --no-check-certificate -qO "${client_script}" 'https://raw.githubusercontent.com/cppla/ServerStatus/master/clients/client-linux.py'
    
    echo "请输入ServerStatus服务器信息:"
    read_user_input "服务器IP地址" "" "server_ip"
    read_user_input "用户ID(格式:sxx)" "" "user_id"
    
    echo "=========================================="
    echo "服务器IP: $server_ip"
    echo "用户ID: $user_id"
    echo "=========================================="
    
    if which python >/dev/null 2>&1; then
        echo "使用Python运行客户端..."
        nohup python "${client_script}" SERVER=$server_ip USER=$user_id >/dev/null 2>&1 &
        ps -e | grep python
    else
        echo "使用Python3运行客户端..."
        nohup python3 "${client_script}" SERVER=$server_ip USER=$user_id >/dev/null 2>&1 &
        ps -e | grep python3
    fi
}

function install_xui() {
    echo "开始安装x-ui面板..."
    local install_options="1) 官方版本  2) 开发版本  3) 3x-ui版本(默认)"
    read_user_input "请选择安装版本" "3" "version_choice" "$install_options"
    
    case "$version_choice" in
        1)
            echo "安装x-ui官方版本..."
            bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
            ;;
        2)
            echo "安装x-ui开发版本..."
            bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
            ;;
        3)
            echo "安装3x-ui版本..."
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
        *)
            echo "无效的选项，安装3x-ui版本..."
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
    esac
}

function install_debian_essentials() {
    echo "开始安装Debian必要组件..."
    local debian_script="${TEMP_DIR}/mydebian.sh"
    wget --no-check-certificate -O "${debian_script}" https://raw.githubusercontent.com/hityne/ssh/master/mydebian.sh
    echo "执行安装脚本..."
    bash "${debian_script}"
    echo "必要组件安装完成"
}

function install_docker_aria2() {
    echo "开始安装Docker版Aria2..."
    if ! systemctl is-active docker &>/dev/null; then
        echo "错误: Docker服务未启动"
        read_user_input "是否先安装Docker？(y/n)" "y" "install_docker_first"
        if [ "$install_docker_first" = "y" ]; then
            install_docker_and_docker_compose
        else
            echo "取消安装"
            return 1
        fi
    fi
    
    local aria2_script="${TEMP_DIR}/aria2_docker_install.sh"
    wget --no-check-certificate -O "${aria2_script}" https://raw.githubusercontent.com/hityne/ssh/master/aria2_docker_install.sh
    echo "执行Aria2安装脚本..."
    bash "${aria2_script}"
    echo "Aria2安装完成"
}

function install_tinyproxy() {
    echo "开始安装TinyProxy代理服务器..."
    local tinyproxy_script="${TEMP_DIR}/install_tinyproxy.sh"
    wget --no-check-certificate -O "${tinyproxy_script}" https://github.com/hityne/ssh/raw/master/install_tinyproxy.sh
    echo "执行TinyProxy安装脚本..."
    bash "${tinyproxy_script}"
    echo "TinyProxy安装完成"
}

function download_frp() {
    echo "开始下载FRP内网穿透工具..."
    local version_options="1) v0.49.0(默认)  2) 其他版本"
    read_user_input "请选择FRP版本" "1" "frp_version" "$version_options"
    
    if [ "$frp_version" = "1" ]; then
        local frp_package="${TEMP_DIR}/frp_0.49.0_linux_amd64.tar.gz"
        wget --no-check-certificate -O "${frp_package}" https://github.com/fatedier/frp/releases/download/v0.49.0/frp_0.49.0_linux_amd64.tar.gz
        echo "FRP v0.49.0下载完成: ${frp_package}"
    else
        read_user_input "请输入版本号(例如: 0.48.0)" "" "custom_version"
        local frp_package="${TEMP_DIR}/frp_${custom_version}_linux_amd64.tar.gz"
        wget --no-check-certificate -O "${frp_package}" "https://github.com/fatedier/frp/releases/download/v${custom_version}/frp_${custom_version}_linux_amd64.tar.gz"
        echo "FRP v${custom_version}下载完成: ${frp_package}"
    fi
}

function modify_ssh_port() {
    echo "修改SSH端口"
    echo "----------------------------------------"
    read_user_input "请输入新的SSH端口" "22" "new_ssh_port"
    
    echo "=========================================="
    echo "新SSH端口: $new_ssh_port"
    echo "=========================================="
    read -n 1 -p "按任意键继续..."
    
    old_port=$(sed -n '/^Port/'p /etc/ssh/sshd_config)
    if [ -z "$old_port" ]; then
        echo "未找到原SSH端口配置，添加新配置..."
        echo "Port $new_ssh_port" >> /etc/ssh/sshd_config
    else
        echo "修改SSH端口配置..."
        sed -i "s/$old_port/Port $new_ssh_port/g" /etc/ssh/sshd_config
    fi
    
    systemctl restart ssh
    echo "SSH服务已重启，请使用新端口 $new_ssh_port 登录"
}

function unixbench_score() {
    local unixbench_script="${TEMP_DIR}/unixbench.sh"
    wget --no-check-certificate -O "${unixbench_script}" https://github.com/teddysun/across/raw/master/unixbench.sh
    chmod +x "${unixbench_script}"
    bash "${unixbench_script}"
}

function install_docker_and_docker_compose() {
    local docker_script="${TEMP_DIR}/get-docker.sh"
    read_user_input "是否安装 Docker 服务？(y/n)" "y" "install_docker_choice"
    
    if [ "$install_docker_choice" != "n" ]; then
        echo "正在安装 Docker..."
        curl -fsSL https://get.docker.com -o "${docker_script}"
        sh "${docker_script}"
        systemctl enable docker
        systemctl start docker
        echo "Docker 服务已安装并启动"
    fi
    
    read_user_input "是否安装 Docker Compose？(y/n)" "y" "install_compose_choice"
    if [ "$install_compose_choice" != "n" ]; then
        echo "正在安装 Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        docker-compose --version
        echo "Docker Compose 安装完成"
    fi
}

function set_localtime_to_china_zone() {
    echo "设置系统时区为中国时区..."
    rm -rf /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date -R
    
    local sync_options="y) 开启自动同步  n) 不开启(默认)"
    read_user_input "是否开启开机自动同步时间" "n" "auto_sync" "$sync_options"
    
    if [ "$auto_sync" = "y" ]; then
        local mystart_script="${TEMP_DIR}/mystart.sh"
        echo "配置自动同步..."
        wget --no-check-certificate -O "${mystart_script}" https://github.com/hityne/ssh/raw/master/mystart.sh
        chmod +x "${mystart_script}"
        mv "${mystart_script}" /etc/init.d/mystart.sh
        update-rc.d mystart.sh defaults
        echo "正在同步时间..."
        /usr/sbin/ntpdate time.nist.gov|logger -t NTP
        /usr/sbin/hwclock -w
        date -R
        echo "时间同步配置完成"
    fi
}

function vps_info() {
    local info_script="${TEMP_DIR}/dmytest.sh"
    wget --no-check-certificate -O "${info_script}" https://github.com/hityne/ssh/raw/master/dmytest.sh
    chmod +x "${info_script}"
    bash "${info_script}"
}

function test_speed() {
    echo "开始测试服务器网速..."
    echo "----------------------------------------"
    local speed_options="1) Bench.sh  2) Speedtest(默认)"
    read_user_input "请选择测速工具" "2" "speed_tool" "$speed_options"
    
    if [ "$speed_tool" = "1" ]; then
        wget -qO- bench.sh | bash
    else
        if ! command -v speedtest &>/dev/null; then
            echo "安装Speedtest CLI..."
            curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
            apt install speedtest
        fi
        echo "执行Speedtest测速..."
        speedtest
    fi
}

function install_python3() {
    echo "开始安装Python3..."
    local version_options="0) Python 3.10.11  1) Python 3.9.16"
    read_user_input "请选择Python版本" "0" "python_version" "$version_options"
    
    local install_script="${TEMP_DIR}/install_python.sh"
    if [ "$python_version" = "0" ]; then
        echo "准备安装Python 3.10.11..."
        wget --no-check-certificate -O "${install_script}" https://github.com/hityne/ssh/raw/master/install_python3.10_on_debain11.sh
    else
        echo "准备安装Python 3.9.16..."
        wget --no-check-certificate -O "${install_script}" https://github.com/hityne/ssh/raw/master/install_python3.9_on_debian11.sh
    fi
    
    chmod +x "${install_script}"
    echo "开始安装Python..."
    bash "${install_script}"
    echo "Python安装完成"
}

# 修改主函数调用
function main() {
    show_menu
    read_user_input "请输入选项编号" "" "main_no"
    handle_menu "$main_no"
}

# 调用主函数替代直接调用
main

# 在脚本结束时清理
trap cleanup_temp EXIT
# 添加基础包检查函数
function check_basic_packages() {
    local packages=("wget" "curl")
    local need_update=0
    
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            echo "安装必要组件: $pkg"
            if [ $need_update -eq 0 ]; then
                apt update
                need_update=1
            fi
            apt install -y "$pkg"
        fi
    done
}

# 在脚本开始处替换原有的包检查代码
check_basic_packages

