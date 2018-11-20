#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 7+/Ubuntu 14.04+
#	Description: ShadowsocksR Port-IP Check
#	Version: 1.0.6
#	Author: Toyo
#	Blog: https://doub.io/ss-jc50/
#=================================================
IP_threshold=3
# IP阈值
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[33m" && Purple_font_prefix="\033[35m"
Sky_blue_font_prefix="\033[36m" && Blue_font_prefix="\033[34m"
Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
# ——————————————————————————————
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	#bit=`uname -m`
}
check_pid(){
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[[ -z ${PID} ]] && echo -e "${Error} ShadowsocksR服务端没有运行，请检查 !" && exit 1
}
scan_port_centos(){
	port=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $4}' |awk -F ":" '{print $NF}' |sort -u`
	port_num=`echo "${port}" |wc -l`
	[[ -z ${port} ]] && echo -e "${Error} 没有发现正在链接的端口 !" && exit 1
	[[ ${port_num} = 0 ]] && echo -e "${Error} 没有发现正在链接的端口 !" && exit 1
}
scan_port_debian(){
	port=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $4}' |awk -F ":" '{print $NF}' |sort -u`
	port_num=`echo "${port}" |wc -l`
	[[ -z ${port} ]] && echo -e "${Error} 没有发现正在链接的端口 !" && exit 1
	[[ ${port_num} = 0 ]] && echo -e "${Error} 没有发现正在链接的端口 !" && exit 1
}
scan_ip_centos(){
	ip=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
	ip_num=`echo "${ip}" |wc -l`
	[[ -z ${ip} ]] && echo -e "${Error} 没有发现正在链接的IP !" && exit 1
	[[ ${ip_num} = 0 ]] && echo -e "${Error} 没有发现正在链接的IP !" && exit 1
}
scan_ip_debian(){
	ip=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
	ip_num=`echo "${ip}" |wc -l`
	[[ -z ${ip} ]] && echo -e "${Error} 没有发现正在链接的IP !" && exit 1
	[[ ${ip_num} = 0 ]] && echo -e "${Error} 没有发现正在链接的IP !" && exit 1
}
check_threshold_centos(){
	for((integer = ${port_num}; integer >= 1; integer--))
	do
		port_check=`echo "${port}" |sed -n "$integer"p`
		ip_check_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${port_check}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
		ip_num=`echo "${ip_check_1}" |wc -l`
		if [[ ${action_2} == "y" ]]; then
			get_IP_address
		else
			ip_check=`echo -e "\n${ip_check_1}"`
		fi
		[[ ${ip_num} -ge ${IP_threshold} ]] && echo -e " 端口: ${Red_font_prefix}${port_check}${Font_color_suffix} ,IP总数: ${Red_font_prefix}${ip_num}${Font_color_suffix} ,IP: ${Sky_blue_font_prefix}$(echo "${ip_check}")${Font_color_suffix}"
		ip_check=""
	done
}
check_threshold_debian(){
	[[ ${action_2} == "y" ]] && echo -e "${Tip} 检测IP归属地(ipip.net)，如果IP较多，可能时间会比较长..."
	for((integer = ${port_num}; integer >= 1; integer--))
	do
		port_check=`echo "${port}" |sed -n "$integer"p`
		ip_check_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${port_check}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
		ip_num=`echo "${ip_check_1}" |wc -l`
		if [[ ${action_2} == "y" ]]; then
			get_IP_address
		else
			ip_check=`echo -e "\n${ip_check_1}"`
		fi
		[[ ${ip_num} -ge ${IP_threshold} ]] && echo -e " 端口: ${Red_font_prefix}${port_check}${Font_color_suffix} ,IP总数: ${Red_font_prefix}${ip_num}${Font_color_suffix} ,IP: ${Sky_blue_font_prefix}$(echo "${ip_check}")${Font_color_suffix}"
		ip_check=""
	done
}
get_IP_address(){
	#echo "port_check=${port_check}"
	#echo "ip_check_1=${ip_check_1}"
	if [[ ${ip_num} -ge ${IP_threshold} ]]; then
		if [[ ! -z ${ip_check_1} ]]; then
			#echo "ip_num=${ip_num}"
			for((integer_1 = ${ip_num}; integer_1 >= 1; integer_1--))
			do
				IP=`echo "${ip_check_1}" |sed -n "$integer_1"p`
				#echo "IP=${IP}"
				IP_address=`wget -qO- -t1 -T2 http://freeapi.ipip.net/${IP}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g'`
				#echo "IP_address=${IP_address}"
				ip_check="${ip_check}\n${IP}(${IP_address})"
				#echo "ip_check=${ip_check}"
				# echo "${IP}(${IP_address})"
				sleep 1s
			done
		fi
	fi
}
c_ssr(){
	check_pid
	if [[ ${release} == "centos" ]]; then
		scan_port_centos
		echo -e "当前时间：${Yellow_font_prefix}$(date "+%Y-%m-%d %H:%M:%S %u %Z")${Font_color_suffix}\n"
		check_threshold_centos
	else
		scan_port_debian
		echo -e "当前时间：${Yellow_font_prefix}$(date "+%Y-%m-%d %H:%M:%S %u %Z")${Font_color_suffix}\n"
		check_threshold_debian
	fi
}
a_ssr(){
	check_pid
	IP_threshold=1
	if [[ ${release} == "centos" ]]; then
		scan_port_centos
		scan_ip_centos
		echo -e "当前时间：${Yellow_font_prefix}$(date "+%Y-%m-%d %H:%M:%S %u %Z")${Font_color_suffix} ,当前链接的端口共 ${Red_font_prefix}${port_num}${Font_color_suffix} ,当前链接的IP共 ${Red_font_prefix}${ip_num}${Font_color_suffix} \n"
		check_threshold_centos
	else
		scan_port_debian
		scan_ip_debian
		echo -e "当前时间：${Yellow_font_prefix}$(date "+%Y-%m-%d %H:%M:%S %u %Z")${Font_color_suffix} ,当前链接的端口共 ${Red_font_prefix}${port_num}${Font_color_suffix} ,当前链接的IP共 ${Red_font_prefix}${ip_num}${Font_color_suffix} \n"
		check_threshold_debian
	fi
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
action=$1
action_2=$2
[[ -z $1 ]] && action=c
case "$action" in
    c|a)
    ${action}_ssr
    ;;
    *)
    echo -e "输入错误 !
 用法: 
 c 检查并显示 超过IP阈值的端口
 a 显示当前 所有端口IP连接信息
 y 显示IP归属地(这是第二个参数如：bash ssr_ip_check.sh a y)"
    ;;
esac