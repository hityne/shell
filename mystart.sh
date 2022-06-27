#!/bin/sh

### BEGIN INIT INFO
# Provides: mystart
# Required-Start: networkremote_fs local_fs
# Required-Stop:network remote_fslocal_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: mystart
# Description: executed when the system starts
### END INIT INFO

service ntp stop                 #停止ntp服务
ntpdate us.pool.ntp.org           #同步ntp时间
service ntp start                #启动ntp服务

exit 0