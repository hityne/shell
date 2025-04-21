#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 定义颜色变量
RED='\E[1;31m'       # 红
GREEN='\E[1;32m'    # 绿
YELLOW='\E[1;33m'    # 黄
BLUE='\E[1;34m'     # 蓝
PINK='\E[1;35m'     # 粉红
RES='\E[0m'          # 清除颜色

# 定义临时目录
TEMP_DIR="/tmp/vps_script"

# 定义GitHub镜像源
GITHUB_MIRROR=""

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

GetIp

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

# 修改GitHub镜像源选择函数
function init_github_mirror() {
    clear
    echo ""
    echo "Please select a GitHub mirror source"
    echo ""
    local mirror_options="1) visit directly(default)  2) ghproxy.cc"
    read_user_input "Your choice" "1" "github_mirror" "$mirror_options"
    
    case "$github_mirror" in
        1)
            GITHUB_MIRROR=""
            ;;
        2)
            GITHUB_MIRROR="https://www.ghproxy.cc/"
            ;;
        *)
            GITHUB_MIRROR="https://github.com"
            ;;
    esac
}

# 修改主函数
function main() {
    # 初始化GitHub镜像源
    init_github_mirror
    
    # 引入功能模块
    source "${SCRIPT_DIR}/functions.sh"
    
    show_menu
    read_user_input "请输入选项编号" "" "main_no"
    handle_menu "$main_no"
}

# 调用主函数
main

# 在脚本结束时清理
trap cleanup_temp EXIT

