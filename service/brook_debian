#!/bin/bash

### BEGIN INIT INFO
# Provides:          Brook
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Lightweight SOCKS5 proxy tool
# Description:       Start or stop the Brook
### END INIT INFO

NAME="Brook"
NAME_BIN="./brook "
FILE="/usr/local/brook"
CONF="/usr/local/brook/brook.conf"
LOG="/usr/local/brook/brook.log"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
RETVAL=0

check_running(){
	PID=`ps -ef |grep "${NAME_BIN}" |grep -v "grep" |grep -v "brook.sh" |grep -v "init.d" |grep -v "service" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		return 0
	else
		return 1
	fi
}
read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} Brook 配置文件不存在 !" && exit 1
	user_all=$(cat ${CONF}|sed "1d")
	user_all_num=$(echo "${user_all}"|wc -l)
	[[ -z ${user_all} ]] && echo -e "${Error} Brook 配置文件中用户配置为空 !" && exit 1
	protocol=$(cat ${CONF}|sed -n "1p")
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
		servers_all=""
		for((integer = 1; integer <= ${user_all_num}; integer++))
		do
			user_text=$(echo "${user_all}"|sed -n "${integer}p")
			port=$(echo "${user_text}"|awk '{print $1}')
			password=$(echo "${user_text}"|awk '{print $2}')
			servers_all="${servers_all}-l \":${port} ${password}\" "
		done
		#echo -e "nohup ./brook ${protocol} $(echo ${servers_all}) >> \"${LOG}\" 2>&1 &"
		eval nohup ./brook ${protocol} $(echo ${servers_all}) >> "${LOG}" 2>&1 &
		sleep 2s
		check_running
		if [[ $? -eq 0 ]]; then
			echo -e "${Info} $NAME 启动成功 !"
		else
			echo -e "${Error} $NAME 启动失败 !"
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