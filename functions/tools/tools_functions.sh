#!/bin/bash

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