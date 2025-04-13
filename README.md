# Linux VPS 管理脚本

一个功能强大的 Linux VPS 管理脚本，提供系统安装、优化、面板安装等多种功能。

## 主要功能

### 系统相关
- 安装 Debian 12 系统
- 安装 BBR 加速
- 安装宝塔面板（支持国际版和中文版）
- 修改 SSH 端口
- 设置中国时区
- 安装 Debian 必备组件

### 网络相关
- 安装 V2ray
- 安装 X-UI（支持多个版本）
- 安装 ServerStatus（服务端和客户端）
- 安装 TinyProxy
- 下载 FRP 内网穿透工具

### Docker 相关
- 安装 Docker 和 Docker Compose
- 安装 Docker Filerun
- 安装 Docker Aria2

### 工具相关
- UnixBench 性能测试
- 网速测试（支持 Bench.sh 和 Speedtest）
- VPS 信息查看
- Python3 安装（支持 3.9 和 3.10 版本）

## 使用说明

1. 确保使用 root 用户运行脚本
2. 执行以下命令：
```bash
wget -O main.sh https://raw.githubusercontent.com/your-repo/main.sh
chmod +x main.sh
./main.sh
```

## 特点

- 支持临时文件管理，自动清理
- 提供彩色终端输出
- 支持用户交互式选择
- 自动检查并安装必要依赖
- 支持多种安装选项和配置

## 注意事项

- 部分功能需要网络连接
- 某些操作可能需要重启服务器
- 建议在操作前备份重要数据

## 免责声明

本脚本仅供学习和参考使用，请遵守当地法律法规。使用本脚本造成的任何问题，作者不承担任何责任。

## 更新日志

- 2025/01/25: 初始版本发布
