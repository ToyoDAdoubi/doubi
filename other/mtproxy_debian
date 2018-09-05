#!/bin/bash

### BEGIN INIT INFO
# Provides:          MTProxy
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Simple MT-Proto proxy
# Description:       Start or stop the MTProxy
### END INIT INFO

NAME="MTProxy"
NAME_BIN="./mtproto-proxy"
FILE="/usr/local/mtproxy"
CONF="/usr/local/mtproxy/mtproxy.conf"
LOG="/usr/local/mtproxy/mtproxy.log"

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
	[[ ! -e ${CONF} ]] && echo -e "${Error} MTProxy 配置文件不存在 !" && exit 1
	port=$(cat ${CONF}|grep 'PORT = '|awk -F 'PORT = ' '{print $NF}')
	passwd=$(cat ${CONF}|grep 'PASSWORD = '|awk -F 'PASSWORD = ' '{print $NF}')
	tag=$(cat ${CONF}|grep 'TAG = '|awk -F 'TAG = ' '{print $NF}')
	nat=$(cat ${CONF}|grep 'NAT = '|awk -F 'NAT = ' '{print $NF}')
	[[ ! -z "${tag}" ]] && tag="-P \"${tag}\""
	[[ ! -z "${nat}" ]] && nat="--nat-info \"${nat}\""
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
		eval nohup ./mtproto-proxy -u nobody -p 65432 -H ${port} -S "${passwd}" $(echo ${tag}) $(echo ${nat}) --aes-pwd proxy-secret proxy-multi.conf >> "${LOG}" 2>&1 &
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
	echo "使用方法: $0 { start | stop | restart | status }"
	RETVAL=1
	;;
esac
exit $RETVAL