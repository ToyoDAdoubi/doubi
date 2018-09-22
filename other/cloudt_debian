#!/bin/bash

### BEGIN INIT INFO
# Provides:          Cloud-Torrent
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Cloud Torrent: a self-hosted remote torrent client
# Description:       Start or stop the Cloud Torrent
### END INIT INFO

NAME="Cloud Torrent"
NAME_BIN="cloud-torrent"
FILE="/usr/local/cloudtorrent"
BIN="${FILE}/cloud-torrent"
CONFIG="${FILE}/cloud-torrent.json"
CONF="${FILE}/cloud-torrent.conf"
LOG="/tmp/ct.log"

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
	host=`cat ${CONF}|grep "host = "|awk -F "host = " '{print $NF}'`
	port=`cat ${CONF}|grep "port = "|awk -F "port = " '{print $NF}'`
	user=`cat ${CONF}|grep "user = "|awk -F "user = " '{print $NF}'`
	passwd=`cat ${CONF}|grep "passwd = "|awk -F "passwd = " '{print $NF}'`
}
View_User(){
	if [[ "${host}" == "0.0.0.0" ]]; then
		host=$(wget -qO- -t1 -T2 ipinfo.io/ip)
		if [[ -z "${host}" ]]; then
			host=$(wget -qO- -t1 -T2 api.ip.sb/ip)
			if [[ -z "${host}" ]]; then
				host=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
				if [[ -z "${host}" ]]; then
					host="VPS_IP"
				fi
			fi
		fi
	fi
	if [[ "${port}" == "80" ]]; then
		port=""
	else
		port=":${port}"
	fi
	if [[ -z ${user} ]]; then
		clear && echo "————————————————" && echo
		echo -e " 你的 Cloud Torrent 信息 :" && echo
		echo -e " 地址\t: ${Green_font_prefix}http://${host}${port}${Font_color_suffix}"
		echo && echo "————————————————"
	else
		clear && echo "————————————————" && echo
		echo -e " 你的 Cloud Torrent 信息 :" && echo
		echo -e " 地址\t: ${Green_font_prefix}http://${host}${port}${Font_color_suffix}"
		echo -e " 用户\t: ${Green_font_prefix}${user}${Font_color_suffix}"
		echo -e " 密码\t: ${Green_font_prefix}${passwd}${Font_color_suffix}"
		echo && echo "————————————————"
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
		if [[ -z ${user} ]]; then
			./cloud-torrent -t "Cloud Torrent - DOUBI" -h "${host}" -p ${port} -l >> "${LOG}" 2>&1 &
		else
			./cloud-torrent -t "Cloud Torrent - DOUBI" -h "${host}" -p ${port} -l -a "${user}:${passwd}" >> "${LOG}" 2>&1 &
		fi
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