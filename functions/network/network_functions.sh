#!/bin/bash

function install_v2ray() {
    local v2ray_script="${TEMP_DIR}/v2ray.sh"
    wget --no-check-certificate -O "${v2ray_script}" "${GITHUB_MIRROR}/hityne/others/raw/main/v2ray.sh"
    chmod a+x "${v2ray_script}"
    bash "${v2ray_script}"
}

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

function install_tinyproxy() {
    echo "开始安装TinyProxy代理服务器..."
    local tinyproxy_script="${TEMP_DIR}/install_tinyproxy.sh"
    wget --no-check-certificate -O "${tinyproxy_script}" "${GITHUB_MIRROR}/hityne/ssh/raw/master/install_tinyproxy.sh"
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
        wget --no-check-certificate -O "${frp_package}" "${GITHUB_MIRROR}/fatedier/frp/releases/download/v0.49.0/frp_0.49.0_linux_amd64.tar.gz"
        echo "FRP v0.49.0下载完成: ${frp_package}"
    else
        read_user_input "请输入版本号(例如: 0.48.0)" "" "custom_version"
        local frp_package="${TEMP_DIR}/frp_${custom_version}_linux_amd64.tar.gz"
        wget --no-check-certificate -O "${frp_package}" "${GITHUB_MIRROR}/fatedier/frp/releases/download/v${custom_version}/frp_${custom_version}_linux_amd64.tar.gz"
        echo "FRP v${custom_version}下载完成: ${frp_package}"
    fi
} 