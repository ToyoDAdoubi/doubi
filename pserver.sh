#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Peerflix Server
#	Version: 1.0.3
#	Author: Toyo
#	Blog: https://doub.io/wlzy-13/
#=================================================

node_ver="v6.9.1"
node_file="/etc/node"
ps_file="/etc/node/lib/node_modules/peerflix-server"

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
deliptables(){
	port_total=`netstat -lntp | grep node | awk '{print $4}' | awk -F ":" '{print $4}' | wc -l`
	for((integer = 1; integer <= ${port_total}; integer++))
	do
		port=`netstat -lntp | grep node | awk '{print $4}' | awk -F ":" '{print $4}' | sed -n "${integer}p"`
		if [ ${port} != "" ]; then
			iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		fi
	done
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT
}
# 安装PS
installps(){
# 判断是否安装PS
	if [ -e ${ps_file} ];
	then
		echo -e "\033[41;37m [错误] \033[0m 检测到 Peerflix Server 已安装，如需继续，请先卸载 !"
		exit 1
	fi

	check_sys
# 系统判断
	if [ ${release} == "centos" ]; then
		yum update
		yum install -y build-essential curl vim xz tar
	elif [ ${release} == "debian" ]; then
		apt-get update
		apt-get install -y build-essential curl vim xz tar
	elif [ ${release} == "ubuntu" ]; then
		sudo apt-get update
		sudo apt-get install -y build-essential curl vim xz tar
	else
		echo -e "\033[41;37m [错误] \033[0m 本脚本不支持当前系统 !"
		exit 1
	fi
	
	#修改DNS为8.8.8.8
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	
	if [ ${bit} == "x86_64" ]; then
		wget -N -O node.tar.xz "https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x64.tar.xz"
		xz -d node.tar.xz
		tar -xvf node.tar -C "/etc"
		mv /etc/node-v6.9.1-linux-x64 ${node_file}
		rm -rf node.tar
		ln -s ${node_file}/bin/node /usr/local/bin/node
		ln -s ${node_file}/bin/npm /usr/local/bin/npm
	elif [ ${bit} == "i386" ]; then
		wget -N -O node.tar.xz "https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x86.tar.xz"
		xz -d node.tar.xz
		tar -xvf node.tar -C "/etc"
		mv /etc/node-v6.9.1-linux-x86 ${node_file}
		rm -rf node.tar
		ln -s ${node_file}/bin/node /usr/local/bin/node
		ln -s ${node_file}/bin/npm /usr/local/bin/npm
	else
		echo -e "\033[41;37m [错误] \033[0m 不支持 ${bit} !"
		exit 1
	fi
	
	npm install -g peerflix-server
	
# 判断是否下载成功
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 安装失败 !"
		exit 1
	fi
	startps
}
startps(){
# 检查是否安装
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 没有安装，请检查 !"
		exit 1
	fi
# 判断进程是否存在
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ ! -z $PID ]; then
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 进程正在运行，请检查 !"
		exit 1
	fi
	
	#设置端口
	while true
	do
	echo -e "请输入 Peerflix Server 监听端口 [1-65535]"
	stty erase '^H' && read -p "(默认端口: 9000):" PORT
	[ -z "$PORT" ] && PORT="9000"
	expr ${PORT} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${PORT} -ge 1 ] && [ ${PORT} -le 65535 ]; then
			echo
			echo "——————————————————————————————"
			echo -e "	端口 : \033[41;37m ${PORT} \033[0m"
			echo "——————————————————————————————"
			echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
	
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${PORT} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${PORT} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT

	PORT=${PORT} nohup node ${ps_file}>> ${ps_file}/peerflixs.log 2>&1 &
	
	sleep 2s
	# 判断进程是否存在
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ -z $PID ]; then
		echo
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 启动失败 !"
		exit 1
	fi
	# 获取IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	if [ -z $ip ]; then
		ip="ip"
	fi
	echo
	echo "Peerflix Server 已启动 !"
	echo -e "浏览器访问，地址： \033[41;37m http://${ip}:${PORT} \033[0m "
	echo
}
stopps(){
# 判断进程是否存在
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ -z $PID ]; then
		echo -e "\033[41;37m [错误] \033[0m 没有发现 Peerflix Server 进程运行，请检查 !"
		exit 1
	fi
	deliptables
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ ! -z $PID ];
	then
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 停止失败 !"
		exit 1
	else
		echo
		echo "Peerflix Server 已停止 !"
		echo
	fi
}
# 查看日志
tailps(){
# 判断日志是否存在
	if [ ! -e ${ps_file}/peerflixs.log ];
	then
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 日志文件不存在 !"
		exit 1
	else
		tail -f ${ps_file}/peerflixs.log
	fi
}
autops(){
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 没有安装，开始安装 !"
		installps
	else
		PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
		if [ -z $PID ];
		then
			echo -e "\033[41;37m [错误] \033[0m Peerflix Server 没有启动，开始启动 !"
			startps
		else
			printf "Peerflix Server 正在运行，是否停止 ? (y/N)"
			printf "\n"
			stty erase '^H' && read -p "(默认: n):" autoyn
			[ -z ${autoyn} ] && autoyn="n"
			if [[ ${autoyn} == [Yy] ]]; then
				stopps
			fi
		fi
	fi
}
uninstallps(){
# 检查是否安装
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [错误] \033[0m Peerflix Server 没有安装，请检查 !"
		exit 1
	fi

	printf "确定要卸载 Peerflix Server ? (y/N)"
	printf "\n"
	stty erase '^H' && read -p "(默认: n):" unyn
	[ -z ${unyn} ] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
		if [ ! -z $PID ]; then
			deliptables
			kill -9 ${PID}
		fi
		rm -rf /usr/local/bin/node
		rm -rf /usr/local/bin/npm
		rm -rf ${node_file}
		echo
		echo "Peerflix Server 卸载完成 !"
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
	${action}ps
	;;
	*)
	echo "输入错误 !"
	echo "用法: {install | start | stop | tail | uninstall}"
	;;
esac