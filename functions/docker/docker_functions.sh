#!/bin/bash

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