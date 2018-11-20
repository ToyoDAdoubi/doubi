#!/bin/bash
# chkconfig: 2345 90 10
# description: MTProxy Golang

### BEGIN INIT INFO
# Provides:          MTProxy Golang
# Required-Start:    $network $syslog
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Simple MT-Proto-go proxy
# Description:       Start or stop the MTProxy-go
### END INIT INFO

NAME="MTProxy"
NAME_BIN="./mtg "
FILE="/usr/local/mtproxy-go"
CONF="/usr/local/mtproxy-go/mtproxy.conf"
LOG="/usr/local/mtproxy-go/mtproxy.log"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
RETVAL=0

check_running(){
	PID=$(ps -ef |grep "${NAME_BIN}" |grep -v "grep" |grep -v "init.d" |grep -v "service" |awk '{print $2}')
	if [[ ! -z ${PID} ]]; then
		return 0
	else
		return 1
	fi
}
read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} $NAME 配置文件不存在 !" && exit 1
	port=$(cat ${CONF}|grep 'PORT = '|awk -F 'PORT = ' '{print $NF}')
	password=$(cat ${CONF}|grep 'PASSWORD = '|awk -F 'PASSWORD = ' '{print $NF}')
	tag=$(cat ${CONF}|grep 'TAG = '|awk -F 'TAG = ' '{print $NF}')
	nat_ipv4=$(cat ${CONF}|grep 'NAT-IPv4 = '|awk -F 'NAT-IPv4 = ' '{print $NF}')
	nat_ipv6=$(cat ${CONF}|grep 'NAT-IPv6 = '|awk -F 'NAT-IPv6 = ' '{print $NF}')
	secure=$(cat ${CONF}|grep 'SECURE = '|awk -F 'SECURE = ' '{print $NF}')
	[[ ! -z "${nat_ipv4}" ]] && nat_ipv4="-4 \"${nat_ipv4}\""
	[[ ! -z "${nat_ipv6}" ]] && nat_ipv6="-6 \"${nat_ipv6}\""
	if [[ "${secure}" == "YES" ]]; then
		secure="-s"
	else
		secure=""
	fi
}
do_start(){
	check_running
	if [[ $? -eq 0 ]]; then
		echo -e "${Info} $NAME (PID ${PID}) 正在运行..." && exit 0
	else
		read_config
		cd ${FILE}
		echo -e "${Info} $NAME 启动中..."
		ulimit -n 51200
		eval nohup ./mtg -b 0.0.0.0 -p ${port} $(echo ${nat_ipv4}) $(echo ${nat_ipv6}) -q 65436 $(echo ${secure}) "${password}" "${tag}" >> "${LOG}" 2>&1 &
		sleep 2s
		check_running
		if [[ $? -eq 0 ]]; then
			echo -e "${Info} $NAME 启动成功 !"
		else
			echo -e "${Error} $NAME 启动失败 !请查看日志文件检查问题所在。"
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
	echo -e "使用方法: $0 { start | stop | restart | status }"
	RETVAL=1
	;;
esac
exit $RETVAL