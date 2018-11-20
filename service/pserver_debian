#!/bin/bash

### BEGIN INIT INFO
# Provides:          Peerflix Server
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Peerflix Server: a self-hosted remote torrent client
# Description:       Start or stop the Peerflix Server
### END INIT INFO

NAME="Peerflix Server"
NAME_BIN="peerflix-server"
FILE="/etc/node/lib/node_modules/peerflix-server"
CONF="/etc/peerflix-server/peerflix-server.conf"
LOG="/tmp/peerflix-server.log"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
RETVAL=0

check_running(){
	PID=`ps -ef |grep "${NAME_BIN}" |grep -v "grep" |grep -v "init.d" |grep -v "service" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		return 0
	else
		return 1
	fi
}
read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} ${NAME} 配置文件不存在 !" && exit 1
	port=`cat ${CONF}|grep "port = "|awk -F "port = " '{print $NF}'`
}
View_User(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
	clear && echo "————————————————" && echo
	echo -e " Peerflix Server 信息 :" && echo
	echo -e " 地址\t: ${Green_font_prefix}http://${ip}:${port}${Font_color_suffix}"
	echo && echo "————————————————"
}
do_start(){
	check_running
	if [[ $? -eq 0 ]]; then
		echo -e "${Info} $NAME (PID ${PID}) 正在运行..." && exit 0
	else
		read_config
		echo -e "${Info} $NAME 启动中..."
		ulimit -n 51200
		PORT=${port} nohup node ${FILE} > "${LOG}" 2>&1 &
		sleep 2s
		check_running
		if [[ $? -eq 0 ]]; then
			echo -e "${Info} $NAME 启动成功 !"
			View_User
		else
			echo -e "${Error} $NAME 启动失败(请运行脚本查看日志错误输出) !"
		fi
	fi
}
do_stop(){
	check_running
	if [[ $? -eq 0 ]]; then
		kill -9 ${PID}
		RETVAL=$?
		if [[ $RETVAL -eq 0 ]]; then
			echo -e "${Info} $NAME 停止成功 !"
		else
			echo -e "${Error} $NAME 停止失败 !"
		fi
	else
		echo -e "${Info} $NAME 未运行"
		RETVAL=1
	fi
}
do_status(){
	check_running
	if [[ $? -eq 0 ]]; then
		read_config
		View_User
		echo -e "${Info} $NAME (PID ${PID}) 正在运行..."
	else
		echo -e "${Info} $NAME 未运行 !"
		RETVAL=1
	fi
}
do_restart(){
	do_stop
	do_start
}
case "$1" in
	start|stop|restart|status)
	do_$1
	;;
	*)
	echo "使用方法: $0 { start | stop | restart | status }"
	RETVAL=1
	;;
esac
exit $RETVAL