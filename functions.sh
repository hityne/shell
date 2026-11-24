#!/bin/bash

# ==================== 系统相关功能 ====================

# 安装BBR
function install_bbr() {
    local bbr_script="${TEMP_DIR}/bbr.sh"
    touch /etc/sysctl.conf
    local test1=$(sed -n '/net.ipv4.tcp_congestion_control/p' /etc/sysctl.conf)
    local test2=$(sed -n '/net.core.default_qdisc/p' /etc/sysctl.conf)
    if [[ $test1 == "net.ipv4.tcp_congestion_control = bbr" && $test2 == "net.core.default_qdisc = fq" ]]; then
        echo -e "${GREEN} BBR 已经启用啦...无需再安装${RES}"
    else
        [[ ! $enable_bbr ]] && wget --no-check-certificate -O "${bbr_script}" "${GITHUB_MIRROR}https://github.com/teddysun/across/raw/master/bbr.sh" && chmod 755 "${bbr_script}" && "${bbr_script}" && rm -f "${bbr_script}"
    fi
}

# 重装系统（基于 https://github.com/bin456789/reinstall）
function install_debian12() {
    echo ""
    echo -e "${RED}警告：重装会清空整个硬盘的全部数据！${RES}"
    echo -e "脚本运行后、重启前可随时用 ${YELLOW}bash reinstall.sh reset${RES} 取消重装"
    echo ""
    local confirm_options="1) 继续  2) 取消"
    read_user_input "确认继续吗" "2" "confirm" "$confirm_options"
    if [ "$confirm" != "1" ]; then
        echo "已取消重装"
        return 0
    fi

    local os_options="1) Debian 12  2) Debian 13  3) Ubuntu 22.04  4) Ubuntu 24.04  5) Ubuntu 26.04"
    read_user_input "请选择要安装的系统" "1" "os_choice" "$os_options"

    local distro version
    case "$os_choice" in
        1) distro="debian"; version="12" ;;
        2) distro="debian"; version="13" ;;
        3) distro="ubuntu"; version="22.04" ;;
        4) distro="ubuntu"; version="24.04" ;;
        5) distro="ubuntu"; version="26.04" ;;
        *)
            echo "Invalid option"
            return 1
            ;;
    esac

    local region_options="1) 中国大陆  2) 其他地区"
    read_user_input "请选择您的地区" "2" "region" "$region_options"

    local reinstall_script="${TEMP_DIR}/reinstall.sh"
    if [ "$region" = "1" ]; then
        # 大陆优先用上游官方国内源 cnb.cool，失败再走 gh-proxy.org 加速
        curl -o "${reinstall_script}" https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh || wget -O "${reinstall_script}" https://gh-proxy.org/https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
    else
        curl -o "${reinstall_script}" https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh || wget -O "${reinstall_script}" $_
    fi
    bash "${reinstall_script}" "${distro}" "${version}"
    rm -f "${reinstall_script}"
}

# 安装宝塔面板
function install_bt_panel() {
    local install_script="${TEMP_DIR}/install.sh"
    echo "正在安装国际版面板..."
    wget -O "${install_script}" https://www.aapanel.com/script/install_7.0_en.sh && bash "${install_script}" && rm -f "${install_script}"
}

# 修改SSH端口
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

# 设置中国时区
function set_localtime_to_china_zone() {
    echo "设置系统时区为中国时区..."
    rm -rf /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date -R
    
    local sync_options="y) 开启自动同步  n) 不开启(默认)"
    read_user_input "是否开启开机自动同步时间" "n" "auto_sync" "$sync_options"
    
    if [ "$auto_sync" = "y" ]; then
        if [ ! -x /usr/sbin/ntpdate ]; then
            echo "ntpdate 不存在，尝试安装..."
            apt install -y ntpsec-ntpdate 2>/dev/null || apt install -y ntp
        fi
        local mystart_script="${TEMP_DIR}/mystart.sh"
        echo "配置自动同步..."
        wget --no-check-certificate -O "${mystart_script}" "${GITHUB_MIRROR}https://github.com/hityne/ssh/raw/master/mystart.sh"
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

# 安装Debian必备组件
function install_debian_essentials() {
    echo "开始安装Debian必要组件..."
    
    # 更新和升级
    echo "正在更新系统..."
    apt update && apt dist-upgrade -y
    
    # 安装必要包（Debian 13 起 ntp/ntpdate 被移除，改用 ntpsec-ntpdate，同样提供 /usr/sbin/ntpdate）
    echo "正在安装必要软件包..."
    local version_id
    version_id="$(. /etc/os-release && echo "${VERSION_ID%%.*}")"
    if [ "${version_id:-0}" -ge 13 ]; then
        apt install -y git wget curl vim screen ufw ntpsec-ntpdate
    else
        apt install -y git wget curl vim screen ufw ntp ntpdate
    fi
    
    # 安装语言包
    echo "正在配置语言环境..."
    dpkg-reconfigure locales
    
    # 修改系统语言环境
    echo "正在设置系统语言..."
    echo 'LANG="en_US.UTF-8"' >> /etc/profile
    source /etc/profile
    
    # vim右键复制粘贴
    echo "正在配置vim..."
    wget --no-check-certificate -O /etc/vim/vimrc.local "${GITHUB_MIRROR}https://github.com/hityne/others/raw/main/vimrc.local"
    
    # ssh控制台添加颜色
    echo "正在配置终端颜色..."
    sed -i "\$a\alias ls='ls --color=auto'" /etc/profile
    source /etc/profile
    
    echo "Debian必要组件安装完成"
}

# ==================== 网络相关功能 ====================

# 安装V2ray
function install_v2ray() {
    local v2ray_script="${TEMP_DIR}/v2ray.sh"
    wget --no-check-certificate -O "${v2ray_script}" "${GITHUB_MIRROR}https://github.com/hityne/others/raw/main/v2ray.sh"
    chmod a+x "${v2ray_script}"
    bash "${v2ray_script}"
    rm -f "${v2ray_script}"
}

# 安装X-UI（vaxilu 官方版与 FranzKafkaYu 开发版均已停更/归档，仅保留活跃维护的 3x-ui）
function install_xui() {
    echo "开始安装3x-ui面板..."
    local install_script="${TEMP_DIR}/xui_install.sh"
    wget --no-check-certificate -O "${install_script}" "${GITHUB_MIRROR}https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh"

    if [ -f "${install_script}" ]; then
        chmod +x "${install_script}"
        bash "${install_script}"
        rm -f "${install_script}"
    else
        echo "错误：下载安装脚本失败"
        return 1
    fi
}

# 安装ServerStatus
function install_serverstatus() {
    local install_options="0) 安装服务端  1) 安装客户端"
    read_user_input "请选择安装类型" "0" "install_type" "$install_options"
    
    if [ "$install_type" != "1" ]; then
        install_serverstatus_server
    else
        install_serverstatus_client
    fi
}

# 安装ServerStatus服务端
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
        "${GITHUB_MIRROR}https://github.com/cppla/ServerStatus/raw/master/server/config.json"
    
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

# 安装ServerStatus客户端
function install_serverstatus_client() {
    local client_script="${TEMP_DIR}/client-linux.py"
    mkdir -p /serverclient
    wget --no-check-certificate -qO "${client_script}" "${GITHUB_MIRROR}https://github.com/cppla/ServerStatus/raw/master/clients/client-linux.py"
    
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
    rm -f "${client_script}"
}

# 安装TinyProxy
function install_tinyproxy() {
    echo "开始安装TinyProxy代理服务器..."
    local tinyproxy_script="${TEMP_DIR}/install_tinyproxy.sh"
    wget --no-check-certificate -O "${tinyproxy_script}" "${GITHUB_MIRROR}https://github.com/hityne/ssh/raw/master/install_tinyproxy.sh"
    echo "执行TinyProxy安装脚本..."
    bash "${tinyproxy_script}"
    rm -f "${tinyproxy_script}"
    echo "TinyProxy安装完成"
}

# 下载FRP包
function download_frp() {
    echo "开始下载FRP内网穿透工具..."
    local version_options="1) v0.72.0(默认)  2) 其他版本"
    read_user_input "请选择FRP版本" "1" "frp_version" "$version_options"
    
    if [ "$frp_version" = "1" ]; then
        local frp_package="$(dirname "$0")/frp_0.72.0_linux_amd64.tar.gz"
        wget --no-check-certificate -O "${frp_package}" "${GITHUB_MIRROR}https://github.com/fatedier/frp/releases/download/v0.72.0/frp_0.72.0_linux_amd64.tar.gz"
        echo "FRP v0.72.0下载完成: ${frp_package}"
    else
        read_user_input "请输入版本号(例如: 0.49.0)" "" "custom_version"
        local frp_package="$(dirname "$0")/frp_${custom_version}_linux_amd64.tar.gz"
        wget --no-check-certificate -O "${frp_package}" "${GITHUB_MIRROR}https://github.com/fatedier/frp/releases/download/v${custom_version}/frp_${custom_version}_linux_amd64.tar.gz"
        echo "FRP v${custom_version}下载完成: ${frp_package}"
    fi
}

# ==================== Docker相关功能 ====================

# 安装Docker和Docker Compose
function install_docker_and_docker_compose() {
    local docker_script="${TEMP_DIR}/get-docker.sh"
    read_user_input "是否安装 Docker 服务？(y/n)" "y" "install_docker_choice"
    
    if [ "$install_docker_choice" != "n" ]; then
        echo "正在安装 Docker..."
        curl -fsSL https://get.docker.com -o "${docker_script}"
        sh "${docker_script}"
        systemctl enable docker
        systemctl start docker
        rm -f "${docker_script}"
        echo "Docker 服务已安装并启动"
    fi
    
    read_user_input "是否安装 Docker Compose？(y/n)" "y" "install_compose_choice"
    if [ "$install_compose_choice" != "n" ]; then
        # 新版 Docker 由 get.docker.com 自带 docker compose v2 插件，优先用插件
        if docker compose version &>/dev/null; then
            echo "docker compose 插件已随 Docker 安装:"
            docker compose version
        else
            echo "正在安装 Docker Compose 独立二进制..."
            curl -L "${GITHUB_MIRROR}https://github.com/docker/compose/releases/download/v5.8.0/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
            docker-compose --version
        fi
        echo "Docker Compose 安装完成"
    fi
}

# 安装Docker Filerun
function install_docker_filerun() {
    echo "开始安装Docker版Filerun..."
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
    
    local filerun_script="${TEMP_DIR}/filerun_docker_install.sh"
    wget --no-check-certificate -O "${filerun_script}" "${GITHUB_MIRROR}https://github.com/hityne/ssh/raw/master/filerun_docker_install.sh"
    echo "执行Filerun安装脚本..."
    bash "${filerun_script}"
    rm -f "${filerun_script}"
    echo "Filerun安装完成"
}

# 安装Docker Aria2
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
    wget --no-check-certificate -O "${aria2_script}" "${GITHUB_MIRROR}https://github.com/hityne/ssh/raw/master/aria2_docker_install.sh"
    echo "执行Aria2安装脚本..."
    bash "${aria2_script}"
    rm -f "${aria2_script}"
    echo "Aria2安装完成"
}

# 一键安装 Hermes Agent（https://github.com/NousResearch/hermes-agent）
function install_hermes() {
    if command -v hermes >/dev/null 2>&1; then
        echo -e "${GREEN}Hermes 已安装 ($(hermes --version 2>/dev/null | head -1))，如需更新请运行 hermes update 或重装${RES}"
        return 0
    fi
    echo "正在安装 Hermes Agent（服务器无 GUI，跳过电脑操控组件 cua-driver）..."
    # cua-driver 需要 X11 图形库，无 GUI 的 VPS 用不上；--skip-computer-use 记录跳过偏好
    # 注意：安装器 products 阶段还会无条件刷新工具库里已有的 cua-driver 记录，
    # 失败会直接中断 hermes 命令发布，且不受 --skip 开关控制，需在 config.yaml 关闭该刷新
    local cfg="${HOME}/.hermes/config.yaml"
    if [ -f "$cfg" ]; then
        if grep -q '^updates:' "$cfg"; then
            grep -q 'refresh_cua_driver' "$cfg" || sed -i 's/^updates:[[:space:]]*$/&\n  refresh_cua_driver: false/' "$cfg"
        else
            printf '\nupdates:\n  refresh_cua_driver: false\n' >> "$cfg"
        fi
    fi
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-computer-use
    # 安装器把命令装到 ~/.local/bin，当前 shell 的 PATH 可能还没包含
    export PATH="${HOME}/.local/bin:${PATH}"
    if command -v hermes >/dev/null 2>&1; then
        echo -e "${GREEN}Hermes 安装完成！运行 ${YELLOW}hermes setup${RES}${GREEN} 配置模型和 API 密钥${RES}"
        echo -e "若有工具缺依赖报错，运行 ${YELLOW}hermes pm doctor${RES}${GREEN} 检查修复${RES}"
    else
        echo -e "${YELLOW}hermes 命令暂未进入当前 PATH，重新登录后运行 hermes --version 验证${RES}"
        echo -e "${YELLOW}详细日志: ~/.hermes/logs/install.log${RES}"
    fi
}

# ==================== 工具相关功能 ====================

# UnixBench跑分
function unixbench_score() {
    local unixbench_script="${TEMP_DIR}/unixbench.sh"
    wget --no-check-certificate -O "${unixbench_script}" "${GITHUB_MIRROR}https://github.com/teddysun/across/raw/master/unixbench.sh"
    chmod +x "${unixbench_script}"
    bash "${unixbench_script}"
    rm -f "${unixbench_script}"
}

# 测试网速
function test_speed() {
    echo "开始测试服务器网速..."
    echo "----------------------------------------"
    local speed_options="1) Bench.sh(默认)  2) Speedtest"
    read_user_input "请选择测速工具" "1" "speed_tool" "$speed_options"
    
    if [ "$speed_tool" = "2" ]; then
        if ! command -v speedtest &>/dev/null; then
            echo "安装Speedtest CLI..."
            local speedtest_script="${TEMP_DIR}/speedtest.sh"
            curl -o "${speedtest_script}" https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh
            bash "${speedtest_script}"
            rm -f "${speedtest_script}"
            apt install speedtest
        fi
        echo "执行Speedtest测速..."
        speedtest
    else
        local bench_script="${TEMP_DIR}/bench.sh"
        wget -O "${bench_script}" bench.sh
        chmod +x "${bench_script}"
        bash "${bench_script}"
        rm -f "${bench_script}"
    fi
}

# 查看VPS信息
function vps_info() {
    local info_script="${TEMP_DIR}/dmytest.sh"
    wget --no-check-certificate -O "${info_script}" "${GITHUB_MIRROR}https://github.com/hityne/ssh/raw/master/dmytest.sh"
    chmod +x "${info_script}"
    bash "${info_script}"
    rm -f "${info_script}"
}

# 安装Python3（Debian 12/13 的 apt 自带 3.11/3.13，旧版脚本针对已 EOL 的 Debian 11，已弃用）
function install_python3() {
    echo "正在通过 apt 安装 Python3..."
    apt update && apt install -y python3 python3-pip
    echo "Python3 安装完成:"
    python3 --version
    pip3 --version
} 