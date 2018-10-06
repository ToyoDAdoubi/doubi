#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/java/jre/bin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: GoGo Server
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/wlzy-24/
#=================================================

gogo_directory="/etc/gogoserver"
gogo_file="/etc/gogoserver/gogo-server.jar"
java_directory="/usr/java"
java_file="/usr/java/jre"
profile_file="/etc/profile"
httpsport="8443"

#检查是否安装gogo
check_gogo(){
	[[ ! -e ${gogo_file} ]] && echo -e "\033[41;37m [错误] \033[0m 没有安装GoGo，请检查 !" && exit 1
}
#检查是否安装java
check_java(){
	java_check=`java -version`
	[[ -z ${java_check} ]] && echo -e "\033[41;37m [错误] \033[0m 没有安装JAVA，请检查 !" && exit 1
}
#检查系统
check_sys(){
	bit=`uname -m`
}
# 安装java
installjava(){
	mkdir ${java_directory}
	cd ${java_directory}
	check_sys
# 系统判断
	if [ ${bit} == "x86_64" ]; then
		wget -N -O java.tar.gz "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=216424"
	elif [ ${bit} == "i386" ]; then
		wget -N -O java.tar.gz "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=216422"
	else
		echo -e "\033[41;37m [错误] \033[0m 不支持 ${bit} !" && exit 1
	fi
	tar zxvf java.tar.gz
	jre_file=`ls -a | grep 'jre'`
	mv ${jre_file} jre
	rm -rf java.tar.gz
# 设置java环境变量
	echo '#set java JDK 
JAVA_HOME=/usr/java/jre
JRE_HOME=/usr/java/jre/jre/ 
PATH=$PATH:$JAVA_HOME/bin:$JRE_home/bin 
CLASSPATH=$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar 
export JAVA_HOME 
export JRE_HOME 
export PATH 
export CLASSPATH' >> ${profile_file}
	source ${profile_file}
#判断java是否安装成功
	#java_check=`java -version`
	#[[ -z ${java_check} ]] && echo -e "\033[41;37m [错误] \033[0m 安装 JAVA 失败，请检查 !" && exit 1
}
# 安装gogo
installgogo(){
# 判断是否安装gogo
	[[ -e ${gogo_file} ]] && echo -e "\033[41;37m [错误] \033[0m 已经安装 GoGo，请检查 !" && exit 1
# 判断是否安装java
	#java_check=`java -version`
	if [[ ! -e ${java_directory} ]]; then
		echo -e "\033[42;37m [信息] \033[0m 没有检测到安装 JAVA，开始安装..."
		installjava
	fi
	chmod +x /etc/rc.local
	mkdir ${gogo_directory}
	cd ${gogo_directory}
	wget -N -O gogo-server.jar --no-check-certificate "https://gogohome.herokuapp.com/getLatestGoGoServer"
	#判断gogo是否下载成功
	if [[ ! -e ${gogo_file} ]]; then
		echo -e "\033[41;37m [错误] \033[0m 下载GoGo失败，请检查 !" && exit 1
	else
		startgogo
	fi
}
setgogo(){
#设置端口
	while true
	do
	echo -e "请输入GoGo Server 的 HTTP监听端口 [1-65535]:"
	read -e -p "(默认端口: 8080):" httpport
	[ -z "$httpport" ] && httpport="8080"
	expr ${httpport} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${httpport} -ge 1 ] && [ ${httpport} -le 65535 ]; then
			echo
			echo "——————————————————————————————"
			echo -e "	端口 : \033[41;37m ${httpport} \033[0m"
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
}
# 查看gogo列表
viewgogo(){
# 检查是否安装
	check_gogo
	
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[42;37m [信息] \033[0m GoGo 没有运行 !" && exit 1
	
	gogo_http_port=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $12}'`
# 获取IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	[[ -z $ip ]] && ip="vps_ip"
	echo
	echo "——————————————————————————————"
	echo "	GoGo Server 配置信息: "
	echo
	echo -e "	本地 IP : \033[41;37m ${ip} \033[0m"
	echo -e "	HTTP监听端口 : \033[41;37m ${gogo_http_port} \033[0m"
	echo -e "	HTTPS监听端口 : \033[41;37m ${httpsport} \033[0m"
	echo "——————————————————————————————"
	echo
}
# 启动aProxy
startgogo(){
# 检查是否安装
	check_gogo
# 判断进程是否存在
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ ! -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m 发现 GoGo 正在运行，请检查 !" && exit 1
	cd ${gogo_directory}
	setgogo
	nohup java -Xmx300m -jar gogo-server.jar ${httpport} &>/dev/null &
	sleep 2s
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m GoGo 启动失败 !" && exit 1
	iptables -I INPUT -p tcp --dport ${httpport} -j ACCEPT
	iptables -I INPUT -p udp --dport ${httpport} -j ACCEPT
	iptables -I INPUT -p tcp --dport ${httpsport} -j ACCEPT
	iptables -I INPUT -p udp --dport ${httpsport} -j ACCEPT
# 系统判断,开机启动
	check_sys
	if [[ ${release}  == "debian" ]]; then
		sed -i '$d' /etc/rc.local
		echo -e "nohup java -Xmx300m -jar gogo-server.jar ${httpport} &>/dev/null &" >> /etc/rc.local
		echo -e "exit 0" >> /etc/rc.local
	else
		echo -e "nohup java -Xmx300m -jar gogo-server.jar ${httpport} &>/dev/null &" >> /etc/rc.local
	fi
	
	clear
	echo
	echo "——————————————————————————————"
	echo
	echo "	GoGo 已启动 !"
	viewgogo
}
# 停止aProxy
stopgogo(){
# 检查是否安装
	check_gogo
# 判断进程是否存在
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m 发现 GoGo 没有运行，请检查 !" && exit 1
	gogo_http_port=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $12}'`
	sed -i "/nohup java -Xmx300m -jar gogo-server.jar ${gogo_http_port} &>\/dev\/null &/d" /etc/rc.local
	iptables -D INPUT -p tcp --dport ${gogo_http_port} -j ACCEPT
	iptables -D INPUT -p udp --dport ${gogo_http_port} -j ACCEPT
	iptables -D INPUT -p tcp --dport ${httpsport} -j ACCEPT
	iptables -D INPUT -p udp --dport ${httpsport} -j ACCEPT
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[41;37m [错误] \033[0m GoGo 停止失败 !" && exit 1
	else
		echo "	GoGo 已停止 !"
	fi
}
restartgogo(){
# 检查是否安装
	check_gogo
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ ! -z $PID ]] && stopgogo
	startgogo
}
statusgogo(){
# 检查是否安装
	check_gogo
# 判断进程是否存在
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[42;37m [信息] \033[0m GoGo 正在运行，PID: ${PID} !"
	else
		echo -e "\033[42;37m [信息] \033[0m GoGo 没有运行 !"
	fi
}
uninstallgogo(){
# 检查是否安装
	check_gogo
	printf "确定要卸载 GoGo ? (y/N)"
	printf "\n"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
		[[ ! -z $PID ]] && stopgogo
		rm -rf ${gogo_directory}
		sed -i "/nohup java -Xmx300m -jar gogo-server.jar ${gogo_http_port} &>\/dev\/null &/d" /etc/rc.local
		[[ -e ${gogo_directory} ]] && echo -e "\033[41;37m [错误] \033[0m GoGo卸载失败，请检查 !" && exit 1
		echo
		echo "	GoGo 已卸载 !"
		echo
	else
		echo
		echo "卸载已取消..."
		echo
	fi
}

action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|view|start|stop|restart|status|uninstall)
	${action}gogo
	;;
	*)
	echo "输入错误 !"
	echo "用法: { install | view | start | stop | restart | status | uninstall }"
	;;
esac