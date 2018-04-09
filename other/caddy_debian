#!/bin/bash

### BEGIN INIT INFO
# Provides:          Caddy
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: The HTTP/2 web server with automatic HTTPS
# Description:       Start or stop the Caddy server
### END INIT INFO

NAME="Caddy"
NAME_BIN="caddy"
BIN="/usr/local/caddy/caddy"
if [ -f "/usr/local/caddy/Caddyfile" ]; then
	CONF="/usr/local/caddy/Caddyfile"
elif [ -f "/etc/caddy/Caddyfile" ]; then
	CONF="/etc/caddy/Caddyfile"
fi
Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"
RETVAL=0

check_running(){
	PID=`ps -ef |grep "${NAME_BIN}" |grep -v "grep" |grep -v "init.d" |grep -v "service" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		return 0
	else
		return 1
	fi
}
do_start(){
	check_running
	if [[ $? -eq 0 ]]; then
		echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME (PID ${PID}) 正在运行..." && exit 0
	else
		ulimit -n 51200
		nohup "$BIN" --conf="$CONF" -agree >> /tmp/caddy.log 2>&1 &
		sleep 2s
		check_running
		if [[ $? -eq 0 ]]; then
			echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME 启动成功 !"
		else
			echo -e "${Error_font_prefix}[错误]${Font_suffix} $NAME 启动失败 !"
		fi
	fi
}
do_stop(){
	check_running
	if [[ $? -eq 0 ]]; then
		kill -9 ${PID}
		RETVAL=$?
		if [[ $RETVAL -eq 0 ]]; then
			echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME 停止成功 !"
		else
			echo -e "${Error_font_prefix}[错误]${Font_suffix}$NAME 停止失败 !"
		fi
	else
		echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME 未运行 !"
		RETVAL=1
	fi
}
do_status(){
	check_running
	if [[ $? -eq 0 ]]; then
		echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME (PID ${PID}) 正在运行..."
	else
		echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME 未运行 !"
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