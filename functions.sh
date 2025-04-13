#!/bin/bash

# ==================== 系统相关功能 ====================

# 安装BBR
function install_bbr() {
    local bbr_script="${TEMP_DIR}/bbr.sh"
    local test1=$(sed -n '/net.ipv4.tcp_congestion_control/p' /etc/sysctl.conf)
    local test2=$(sed -n '/net.core.default_qdisc/p' /etc/sysctl.conf)
    if [[ $test1 == "net.ipv4.tcp_congestion_control = bbr" && $test2 == "net.core.default_qdisc = fq" ]]; then
        echo -e "${GREEN} BBR 已经启用啦...无需再安装${RES}"
    else
        [[ ! $enable_bbr ]] && wget --no-check-certificate -O "${bbr_script}" "${GITHUB_MIRROR}/teddysun/across/raw/master/bbr.sh" && chmod 755 "${bbr_script}" && "${bbr_script}"
    fi
}

# 安装Debian 12
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

# 安装宝塔面板
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
            wget --no-check-certificate -O "${panel_zip}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/LinuxPanel-7.7.0.zip"
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
        local mystart_script="${TEMP_DIR}/mystart.sh"
        echo "配置自动同步..."
        wget --no-check-certificate -O "${mystart_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/mystart.sh"
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
    
    # 安装必要包
    echo "正在安装必要软件包..."
    apt install -y git wget curl vim screen ufw ntp ntpdate
    
    # 安装语言包
    echo "正在配置语言环境..."
    dpkg-reconfigure locales
    
    # 修改系统语言环境
    echo "正在设置系统语言..."
    echo 'LANG="en_US.UTF-8"' >> /etc/profile
    source /etc/profile
    
    # vim右键复制粘贴
    echo "正在配置vim..."
    wget --no-check-certificate -O /etc/vim/vimrc.local "${GITHUB_MIRROR}/hityne/others/raw/main/vimrc.local"
    
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
    wget --no-check-certificate -O "${v2ray_script}" "${GITHUB_MIRROR}/hityne/others/raw/main/v2ray.sh"
    chmod a+x "${v2ray_script}"
    bash "${v2ray_script}"
}

# 安装X-UI
function install_xui() {
    echo "开始安装x-ui面板..."
    local install_options="1) 官方版本  2) 开发版本  3) 3x-ui版本(默认)"
    read_user_input "请选择安装版本" "3" "version_choice" "$install_options"
    
    case "$version_choice" in
        1)
            echo "安装x-ui官方版本..."
            bash <(curl -Ls "${GITHUB_MIRROR}/vaxilu/x-ui/raw/master/install.sh")
            ;;
        2)
            echo "安装x-ui开发版本..."
            bash <(curl -Ls "${GITHUB_MIRROR}/FranzKafkaYu/x-ui/raw/master/install.sh")
            ;;
        3)
            echo "安装3x-ui版本..."
            bash <(curl -Ls "${GITHUB_MIRROR}/mhsanaei/3x-ui/raw/master/install.sh")
            ;;
        *)
            echo "无效的选项，安装3x-ui版本..."
            bash <(curl -Ls "${GITHUB_MIRROR}/mhsanaei/3x-ui/raw/master/install.sh")
            ;;
    esac
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
        "${GITHUB_MIRROR}/cppla/ServerStatus/raw/master/server/config.json"
    
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
    wget --no-check-certificate -qO "${client_script}" "${GITHUB_MIRROR}/cppla/ServerStatus/raw/master/clients/client-linux.py"
    
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

# 安装TinyProxy
function install_tinyproxy() {
    echo "开始安装TinyProxy代理服务器..."
    local tinyproxy_script="${TEMP_DIR}/install_tinyproxy.sh"
    wget --no-check-certificate -O "${tinyproxy_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/install_tinyproxy.sh"
    echo "执行TinyProxy安装脚本..."
    bash "${tinyproxy_script}"
    echo "TinyProxy安装完成"
}

# 下载FRP包
function download_frp() {
    echo "开始下载FRP内网穿透工具..."
    local version_options="1) v0.49.0(默认)  2) 其他版本"
    read_user_input "请选择FRP版本" "1" "frp_version" "$version_options"
    
    if [ "$frp_version" = "1" ]; then
        local frp_package="${TEMP_DIR}/frp_0.49.0_linux_amd64.tar.gz"
        wget --no-check-certificate -O "${frp_package}" "${GITHUB_MIRROR}/fatedier/frp/releases/download/v0.49.0/frp_0.49.0_linux_amd64.tar.gz"
        echo "FRP v0.49.0下载完成: ${frp_package}"
    else
        read_user_input "请输入版本号(例如: 0.48.0)" "" "custom_version"
        local frp_package="${TEMP_DIR}/frp_${custom_version}_linux_amd64.tar.gz"
        wget --no-check-certificate -O "${frp_package}" "${GITHUB_MIRROR}/fatedier/frp/releases/download/v${custom_version}/frp_${custom_version}_linux_amd64.tar.gz"
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
        echo "Docker 服务已安装并启动"
    fi
    
    read_user_input "是否安装 Docker Compose？(y/n)" "y" "install_compose_choice"
    if [ "$install_compose_choice" != "n" ]; then
        echo "正在安装 Docker Compose..."
        curl -L "${GITHUB_MIRROR}/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        docker-compose --version
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
    wget --no-check-certificate -O "${filerun_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/filerun_docker_install.sh"
    echo "执行Filerun安装脚本..."
    bash "${filerun_script}"
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
    wget --no-check-certificate -O "${aria2_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/aria2_docker_install.sh"
    echo "执行Aria2安装脚本..."
    bash "${aria2_script}"
    echo "Aria2安装完成"
}

# ==================== 工具相关功能 ====================

# UnixBench跑分
function unixbench_score() {
    local unixbench_script="${TEMP_DIR}/unixbench.sh"
    wget --no-check-certificate -O "${unixbench_script}" "${GITHUB_MIRROR}/teddysun/across/raw/master/unixbench.sh"
    chmod +x "${unixbench_script}"
    bash "${unixbench_script}"
}

# 测试网速
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

# 查看VPS信息
function vps_info() {
    local info_script="${TEMP_DIR}/dmytest.sh"
    wget --no-check-certificate -O "${info_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/dmytest.sh"
    chmod +x "${info_script}"
    bash "${info_script}"
}

# 安装Python3
function install_python3() {
    echo "开始安装Python3..."
    local version_options="0) Python 3.10.11  1) Python 3.9.16"
    read_user_input "请选择Python版本" "0" "python_version" "$version_options"
    
    local install_script="${TEMP_DIR}/install_python.sh"
    if [ "$python_version" = "0" ]; then
        echo "准备安装Python 3.10.11..."
        wget --no-check-certificate -O "${install_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/install_python3.10_on_debain11.sh"
    else
        echo "准备安装Python 3.9.16..."
        wget --no-check-certificate -O "${install_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/install_python3.9_on_debian11.sh"
    fi
    
    chmod +x "${install_script}"
    echo "开始安装Python..."
    bash "${install_script}"
    echo "Python安装完成"
} 