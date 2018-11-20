#!/bin/bash

### BEGIN INIT INFO
# Provides:          DowsDNS
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Lightweight DNS server
# Description:       Start or stop the DowsDNS server
### END INIT INFO


NAME="DowsDNS"
NAME_BIN="python start.py"
BIN="/usr/local/dowsDNS"
CONF="/usr/local/dowsDNS/conf/config.json"
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
Read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} DowsDNS 配置文件不存在 !" && exit 1
	local_dns_port=`cat ${CONF}|grep "Local_dns_port"|sed -r 's/.*:(.+),.*/\1/'`
}
View_dowsdns(){
	Read_config
	if [[ ${local_dns_server} == "127.0.0.1" ]]; then
		ip="${local_dns_server} "
	else
		ip=`wget -qO- -t1 -T2 members.3322.org/dyndns/getip`
		[[ -z ${ip} ]] && ip="VPS_IP"
	fi
	clear && echo "————————————————" && echo
	echo -e " 请在你的设备中设置DNS服务器为：
 IP : ${Info_font_prefix}${ip}${Font_suffix} ,端口 : ${Info_font_prefix}${local_dns_port}${Font_suffix}
 
 注意：如果设备中没有 DNS端口设置选项，那么就只能使用默认的 53 端口"
	echo && echo "————————————————"
}
do_start(){
	check_running
	if [[ $? -eq 0 ]]; then
		echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME (PID $(echo ${PID})) 正在运行..." && exit 0
	else
		cd "${BIN}"
		nohup python start.py > /tmp/dowsdns.log 2>&1 &
		sleep 2s
		check_running
		if [[ $? -eq 0 ]]; then
			View_dowsdns
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
		View_dowsdns
		echo -e "${Info_font_prefix}[信息]${Font_suffix} $NAME (PID $(echo ${PID})) 正在运行..."
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