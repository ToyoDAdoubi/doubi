#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Cloud Torrent
#	Version: 1.0.5
#	Author: Toyo
#	Blog: https://doub.io/wlzy-12/
#=================================================

file="/etc/cloudtorrent"
ct_file="/etc/cloudtorrent/cloud-torrent"
dl_file="/etc/cloudtorrent/downloads"
ct_config="/etc/cloudtorrent/cloud-torrent.json"

#检查系统
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
	bit=`uname -m`
}
#检查版本
check_ver(){
	check_sys
	ct_ver_new=`curl -m 10 -s "https://github.com/jpillora/cloud-torrent/releases/latest" | perl -e 'while($_=<>){ /\/tag\/(.*)\">redirected/; print $1;}'`
	[ ! -e "/etc/cloudtorrent/ct_ver.txt" ] && echo "${ct_ver_new}" > /etc/cloudtorrent/ct_ver.txt
	ct_ver_now=`cat /etc/cloudtorrent/ct_ver.txt`
	
	if [ ${ct_ver_now} != ${ct_ver_new} ]; then
		echo -e "\033[42;37m [信息] \033[0m 发现 Cloud Torrent 已有新版本 [ ${ct_ver_new} ] !"
		read -p "是否更新 ? [Y/n] :" yn1
		[ -z "${yn1}" ] && yn1="y"
		if [[ $yn1 == [Yy] ]]; then
			# 停止CT
			PID=`ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}'`
			kill -9 ${PID}
			cd ${file}
			# 判断位数下载对应版本
			if [ ${bit} == "x86_64" ]; then
				wget -N -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${ct_ver}/cloud-torrent_linux_amd64.gz"
			elif [ ${bit} == "i386" ]; then
				wget -N -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${ct_ver}/cloud-torrent_linux_386.gz"
			else
				echo -e "\033[41;37m [错误] \033[0m 不支持 ${bit} !"
				exit 1
			fi
			# 判断是否下载成功
			if [ ! -e "cloud-torrent.gz" ]; then
				echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 下载失败 !"
				exit 1
			fi
			gzip -d cloud-torrent.gz
			chmod +x cloud-torrent
			#curl i.jpillora.com/cloud-torrent | bash
			echo "${ct_ver}" > ct_ver.txt
			startct
		fi
	fi
}
# 安装CT
installct(){
# 判断是否安装CT
	if [ -e ${ct_file} ]; then
		echo -e "\033[41;37m [错误] \033[0m 检测到 Cloud Torrent 已安装，如需继续，请先卸载 !"
		exit 1
	fi
check_sys
# 系统判断
	if [ ${release}  == "centos" ]; then
		yum update
		yum install -y vim curl gzip
	else
		apt-get update
		apt-get install -y vim curl gzip
	fi
	#修改DNS为8.8.8.8
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	
	mkdir ${file}
	mkdir ${dl_file}
	cd ${file}
	read -p "请输入要安装的 Cloud Torrent 版本号，回车则自动获取最新版本 [ 格式 x.x.xx ] :" ct_ver
	[ -z "${ct_ver}" ] && ct_ver=`curl -m 10 -s "https://github.com/jpillora/cloud-torrent/releases/latest" | perl -e 'while($_=<>){ /\/tag\/(.*)\">redirected/; print $1;}'`
	if [ ${bit} == "x86_64" ]; then
		wget -N -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${ct_ver}/cloud-torrent_linux_amd64.gz"
	elif [ ${bit} == "i386" ]; then
		wget -N -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${ct_ver}/cloud-torrent_linux_386.gz"
	else
		echo -e "\033[41;37m [错误] \033[0m 不支持 ${bit} !" && exit 1
	fi
# 判断是否下载成功
	[ ! -e "cloud-torrent.gz" ] && echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 下载失败 !" && exit 1
	gzip -d cloud-torrent.gz
	chmod +x cloud-torrent
	#curl i.jpillora.com/cloud-torrent | bash
	echo "${ct_ver}" > ct_ver.txt
	startct
}
startct(){
# 判断进程是否存在
	PID=`ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}'`
	[ ! -z $PID ] && echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 进程正在运行，请检查 !" && exit 1
# 判断是否安装CT
	[ ! -e ${ct_file} ] && echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 没有安装，请检查 !" && exit 1
	check_ver
	cd ${file}
# 设置端口
	while true
		do
		echo -e "请输入 Cloud Torrent 监听端口 [1-65535]"
		read -p "(默认端口: 8000):" ctport
		[ -z "$ctport" ] && ctport="8000"
		expr ${ctport} + 0 &>/dev/null
		if [ $? -eq 0 ]; then
			if [ ${ctport} -ge 1 ] && [ ${ctport} -le 65535 ]; then
				echo
				echo "========================"
				echo -e "	端口 : \033[41;37m ${ctport} \033[0m"
				echo "========================"
				echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
		done
	read -p "是否设置 用户名和密码 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
		if [[ $yn == [Yy] ]]; then
			echo "请输入用户名"
			read -p "(默认用户名: user):" ctuser
			[ -z "${ctuser}" ] && ctuser="user"
			echo
			echo "========================"
			echo -e "	用户名 : \033[41;37m ${ctuser} \033[0m"
			echo "========================"
			echo
	
			echo "请输入用户名的密码"
			read -p "(默认密码: doub.io):" ctpasswd
			[ -z "${ctpasswd}" ] && ctpasswd="doub.io"
			echo
			echo "========================"
			echo -e "	密码 : \033[41;37m ${ctpasswd} \033[0m"
			echo "========================"
			echo
	
			./cloud-torrent -p ${ctport} -l -a ${ctuser}:${ctpasswd}>> ct.log 2>&1 &
		else
			./cloud-torrent -p ${ctport} -l >> ct.log 2>&1 &
		fi
	sleep 2s
	PID=`ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}'`
	if [ -z $PID ]; then
		echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 启动失败 !" && exit 1
	else
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ctport} -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ctport} -j ACCEPT
		IncomingPort=`cat ${ct_config} | sed -n "7p" | awk -F ": " '{print $NF}' `
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
		iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
		iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
# 获取IP
		ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
		[ -z $ip ] && ip="VPS_IP"
		echo
		echo "Cloud torrent 已启动 !"
		echo -e "浏览器访问，地址： \033[41;37m http://${ip}:${ctport} \033[0m "
		echo
	fi
}
stopct(){
# 判断进程是否存在
	PID=`ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}'`
	[ -z $PID ] && echo -e "\033[41;37m [错误] \033[0m 没有发现 Cloud Torrent 进程运行，请检查 !" && exit 1
	IncomingPort=`cat ${ct_config} | sed -n "7p" | awk -F ": " '{print $NF}' `
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
	port=`netstat -lntp | grep "${PID}" | awk '{print $4}' | awk -F ":" '{print $NF}' | sed -n "1p"`
	[[ ${port} = ${IncomingPort} ]] && port=`netstat -lntp | grep "${PID}" | awk '{print $4}' | awk -F ":" '{print $NF}' | sed -n "2p"`
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}'`
	if [ ! -z $PID ]; then
		echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 停止失败 !" && exit 1
	else
		echo
		echo "Cloud torrent 已停止 !"
		echo
	fi
}
# 查看日志
tailct(){
# 判断日志是否存在
	if [ ! -e ${file}"/ct.log" ]; then
		echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 日志文件不存在 !" && exit 1
	else
		tail -f /etc/cloudtorrent/ct.log
	fi
}
autoct(){
	if [ ! -e ${ct_file} ]; then
		echo -e "\033[42;37m [信息] \033[0m Cloud Torrent 没有安装，开始安装 !"
		installct
	else
		PID=`ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}'`
		if [ -z $PID ]; then
			echo -e "\033[42;37m [信息] \033[0m Cloud Torrent 没有启动，开始启动 !"
			startct
		else
			echo "Cloud Torrent 正在运行，是否停止 ? (y/N)"
			echo
			read -p "(默认: n):" autoyn
			[ -z ${autoyn} ] && autoyn="n"
			if [[ ${autoyn} == [Yy] ]]; then
				stopct
			fi
		fi
	fi
}
uninstallct(){
# 检查是否安装
	[ ! -e ${file} ] && echo -e "\033[41;37m [错误] \033[0m Cloud Torrent 没有安装，请检查 !" && exit 1
	echo "确定要卸载 Cloud Torrent ? (y/N)"
	echo
	read -p "(默认: n):" unyn
	[ -z ${unyn} ] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}'`
		[ ! -z $PID ] && kill -9 ${PID}
		rm -rf ${file}
		echo
		echo "Cloud torrent 卸载完成 !"
		echo
	else
		echo
		echo "卸载已取消..."
		echo
	fi
}

action=$1
[ -z $1 ] && action=auto
case "$action" in
	auto|install|start|stop|tail|uninstall)
	${action}ct
	;;
	*)
	echo "输入错误 !"
	echo "用法: {install | start | stop | tail | uninstall}"
	;;
esac