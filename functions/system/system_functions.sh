#!/bin/bash

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