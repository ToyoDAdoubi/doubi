#!/bin/bash

### BEGIN INIT INFO
# Provides:          Brook-pf
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Lightweight port forwarding tool
# Description:       Start or stop the Brook-pf
### END INIT INFO

NAME="Brook-pf"
NAME_BIN="brook relays"
FILE="/usr/local/brook-pf"
CONF="${FILE}/brook.conf"
LOG="${FILE}/brook.log"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
RETVAL=0

check_running(){
	PID=`ps -ef |grep "${NAME_BIN}" |grep -v "grep" | grep -v ".sh"| grep -v "init.d" |grep -v "service" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		return 0
	else
		return 1
	fi
}
read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} Brook 配置文件不存在 !" && exit 1
	user_all=$(cat ${CONF}|sed '/^\s*$/d')
	user_all_num=$(echo "${user_all}"|wc -l)
	[[ -z ${user_all} ]] && echo -e "${Error} Brook 配置文件中用户配置为空 !" && exit 1
}
View_User(){
	for((integer = 1; integer <= ${user_all_num}; integer++))
	do
		user_port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
		user_ip_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $2}')
		user_port_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $3}')
		user_Enabled_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $4}')
		if [[ ${user_Enabled_pf} == "0" ]]; then
				user_Enabled_pf_1="${Red_font_prefix}禁用${Font_color_suffix}"
			else
				user_Enabled_pf_1="${Green_font_prefix}启用${Font_color_suffix}"
		fi
		user_list_all=${user_list_all}"本地监听端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 被转发IP: ${Green_font_prefix}"${user_ip_pf}"${Font_color_suffix}\t 被转发端口: ${Green_font_prefix}"${user_port_pf}"${Font_color_suffix}\t 状态: ${user_Enabled_pf_1}\n"
		user_IP=""
	done
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
	echo -e "当前端口转发总数: ${Green_background_prefix} "${user_all_num}" ${Font_color_suffix} 当前服务器IP: ${Green_background_prefix} "${ip}" ${Font_color_suffix}"
	echo -e "${user_list_all}"
	echo -e "========================\n"
}
do_start(){
	check_running
	if [[ $? -eq 0 ]]; then
		echo -e "${Info} ${NAME} (PID ${PID}) 正在运行..." && exit 0
	else
		read_config
		cd ${FILE}
		echo -e "${Info} ${NAME} 启动中..."
		ulimit -n 51200
		servers_all=""
		for((integer = 1; integer <= ${user_all_num}; integer++))
		do
			user_Enabled_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $4}')
			if [[ ${user_Enabled_pf} == "0" ]]; then
				continue
			fi
			user_port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
			user_ip_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $2}')
			user_port_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $3}')
			servers_all="${servers_all}-l \":${user_port} ${user_ip_pf}:${user_port_pf}\" "
		done
		eval nohup ./brook relays $(echo ${servers_all}) >> "${LOG}" 2>&1 &
		sleep 2s
		check_running
		if [[ $? -eq 0 ]]; then
			echo -e "${Info} ${NAME} 启动成功 !"
			View_User
		else
			echo -e "${Error} ${NAME} 启动失败 !"
		fi
	fi
}
do_stop(){
	check_running
	if [[ $? -eq 0 ]]; then
		kill -9 ${PID}
		RETVAL=$?
		if [[ $RETVAL -eq 0 ]]; then
			echo -e "${Info} ${NAME} 停止成功 !"
		else
			echo -e "${Error} ${NAME} 停止失败 !"
		fi
	else
		echo -e "${Info} ${NAME} 未运行"
		RETVAL=1
	fi
}
do_status(){
	check_running
	if [[ $? -eq 0 ]]; then
		read_config
		View_User
		echo -e "${Info} ${NAME} (PID ${PID}) 正在运行..."
	else
		echo -e "${Info} ${NAME} 未运行 !"
		RETVAL=1
	fi
}
do_restart(){
	do_stop
	sleep 2s
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