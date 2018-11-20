#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: HaProxy
#	Version: 1.0.7
#	Author: Toyo
#	Blog: https://doub.io/wlzy-19/
#=================================================

HaProxy_file="/etc/haproxy"
HaProxy_cfg_file="/etc/haproxy/haproxy.cfg"

#检查是否安装HaProxy
check_HaProxy(){
	HaProxy_exist=`haproxy -v`
	if [[ ${HaProxy_exist} = "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 没有安装HaProxy，请检查 !" && exit 1
	fi
}
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
	#bit=`uname -m`
}
# 设置 防火墙规则
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
# 安装HaProxy
installHaProxy(){
	HaProxy_exist=`haproxy -v`
	if [[ ${HaProxy_exist} != "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 已经安装HaProxy，请检查 !" && exit 1
	fi
	if [[ ${release}  == "centos" ]]; then
		yum update && yum install -y vim haproxy
	else
		apt-get update && apt-get install -y vim haproxy
	fi
	chmod +x /etc/rc.local
	HaProxy_exist=`haproxy -v`
	if [[ ${HaProxy_exist} = "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 安装HaProxy失败，请检查 !" && exit 1
	else
		Set_iptables
		if [[ ${release}  == "centos" ]]; then
			cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
			if [[ $? = 0 ]]; then
				systemctl enable haproxy.service
			else
				chmod +x /etc/init.d/haproxy
				chkconfig --add haproxy
				chkconfig haproxy on
			fi
		else
			chmod +x /etc/init.d/haproxy
			update-rc.d -f haproxy defaults
		fi
		setHaProxy
	fi
}
setHaProxy(){
	check_HaProxy
	read -e -p "请输入 HaProxy 的 本地监听端口(转发端口) [1-65535](支持端口段: 2333-6666): " HaProxyport
	[[ -z "${HaProxyport}" ]] && echo "取消..." && exit 1
	read -e -p "请输入 HaProxy 欲转发的 IP:" HaProxyip
	[[ -z "${HaProxyip}" ]] && echo "取消..." && exit 1
	echo
	echo "——————————————————————————————"
	echo "      请检查 HaProxy 配置是否有误 !"
	echo
	echo -e "	本地监听端口 : \033[41;37m ${HaProxyport} \033[0m"
	echo -e "	欲转发 IP : \033[41;37m ${HaProxyip} \033[0m"
	echo "——————————————————————————————"
	echo
	read -e -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	HaProxy_port_1=`cat ${HaProxy_cfg_file} | sed -n "12p" | cut -c 12-23 | grep "-"`
	HaProxy_port=`cat ${HaProxy_cfg_file} | sed -n "12p" | cut -c 12-23`
	if [[ ${HaProxy_port_1} = "" ]]; then
		iptables -D INPUT -p tcp --dport ${HaProxy_port} -j ACCEPT
	else
		HaProxy_port_1=`echo ${HaProxy_port_1} | sed 's/-/:/g'`
		iptables -D INPUT -p tcp --dport ${HaProxy_port_1} -j ACCEPT
	fi
	cat > ${HaProxy_cfg_file}<<-EOF
global

defaults
        log     global
        mode    tcp
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000

frontend ss-in1
    bind *:${HaProxyport}
    default_backend ss-out1

backend ss-out1
    server server1 ${HaProxyip} maxconn 20480
EOF
	restartHaProxy
}
# 查看HaProxy列表
viewHaProxy(){
	check_HaProxy
	HaProxy_port=`cat ${HaProxy_cfg_file} | sed -n "12p" | cut -c 12-23`
	HaProxy_ip=`cat ${HaProxy_cfg_file} | sed -n "16p" | awk '{print $3}'`
	ip=`wget -qO- -t1 -T2 ipinfo.io/ip`
	[[ -z $ip ]] && ip="VPS_IP"
	echo
	echo "——————————————————————————————"
	echo "	HaProxy 配置信息: "
	echo
	echo -e "	本地 IP : \033[41;37m ${ip} \033[0m"
	echo -e "	本地监听端口 : \033[41;37m ${HaProxy_port} \033[0m"
	echo
	echo -e "	欲转发 IP : \033[41;37m ${HaProxy_ip} \033[0m"
	echo -e "	欲转发端口 : \033[41;37m ${HaProxy_port} \033[0m"
	echo "——————————————————————————————"
	echo
}
# 启动aProxy
startHaProxy(){
	check_HaProxy
	PID=`ps -ef | grep "haproxy" | grep -v grep | grep -v "haproxy.sh" | awk '{print $2}'`
	[[ ! -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m 发现 HaProxy 正在运行，请检查 !" && exit 1
	if [[ ${release}  == "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 0 ]]; then
			systemctl start haproxy.service
		else
			/etc/init.d/haproxy start
		fi
	else
		/etc/init.d/haproxy start
	fi
	sleep 2s
	PID=`ps -ef | grep "haproxy" | grep -v grep | grep -v "haproxy.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m HaProxy 启动失败 !" && exit 1
	HaProxy_port_1=`cat ${HaProxy_cfg_file} | sed -n "12p" | cut -c 12-23 | grep "-"`
	HaProxy_port=`cat ${HaProxy_cfg_file} | sed -n "12p" | cut -c 12-23`
	if [[ ${HaProxy_port_1} = "" ]]; then
		iptables -I INPUT -p tcp --dport ${HaProxy_port} -j ACCEPT
	else
		HaProxy_port_1=`echo ${HaProxy_port_1} | sed 's/-/:/g'`
		iptables -I INPUT -p tcp --dport ${HaProxy_port_1} -j ACCEPT
	fi
	echo && echo "——————————————————————————————" && echo
	echo "	HaProxy 已启动 !"
	Save_iptables
	viewHaProxy
}
# 停止aProxy
stopHaProxy(){
	check_HaProxy
	PID=`ps -ef | grep "haproxy" | grep -v grep | grep -v "haproxy.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m 发现 HaProxy 没有运行，请检查 !" && exit 1
	if [[ ${release}  == "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 0 ]]; then
			systemctl stop haproxy.service
		else
			/etc/init.d/haproxy stop
		fi
	else
		/etc/init.d/haproxy stop
	fi
	HaProxy_port_1=`cat ${HaProxy_cfg_file} | sed -n "12p" | cut -c 12-23 | grep "-"`
	HaProxy_port=`cat ${HaProxy_cfg_file} | sed -n "12p" | cut -c 12-23`
	if [[ ${HaProxy_port_1} = "" ]]; then
		iptables -D INPUT -p tcp --dport ${HaProxy_port} -j ACCEPT
	else
		HaProxy_port_1=`echo ${HaProxy_port_1} | sed 's/-/:/g'`
		iptables -D INPUT -p tcp --dport ${HaProxy_port_1} -j ACCEPT
	fi
	sleep 2s
	PID=`ps -ef | grep "haproxy" | grep -v grep | grep -v "haproxy.sh" | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[41;37m [错误] \033[0m HaProxy 停止失败 !" && exit 1
	else
		Save_iptables
		echo "	HaProxy 已停止 !"
	fi
}
restartHaProxy(){
# 检查是否安装
	check_HaProxy
	PID=`ps -ef | grep "haproxy" | grep -v grep | grep -v "haproxy.sh" | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		stopHaProxy
	fi
	startHaProxy
}
statusHaProxy(){
	check_HaProxy
	PID=`ps -ef | grep "haproxy" | grep -v grep | grep -v "haproxy.sh" | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[42;37m [信息] \033[0m HaProxy 正在运行，PID: ${PID} !"
	else
		echo -e "\033[42;37m [信息] \033[0m HaProxy 没有运行 !"
	fi
}
uninstallHaProxy(){
	check_HaProxy
	echo "确定要卸载 HaProxy ? [y/N]"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef | grep "haproxy" | grep -v grep | grep -v "haproxy.sh" | awk '{print $2}'`
		if [[ ! -z $PID ]]; then
			stopHaProxy
		fi
		if [[ ${release}  == "centos" ]]; then
			yum remove haproxy -y
		else
			apt-get remove haproxy -y
			apt-get autoremove
		fi
		rm -rf ${HaProxy_file}
		HaProxy_exist=`haproxy -v`
		if [[ ${HaProxy_exist} != "" ]]; then
			echo -e "\033[41;37m [错误] \033[0m HaProxy卸载失败，请检查 !" && exit 1
		fi
		echo && echo "	HaProxy 已卸载 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
check_sys
action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|set|view|start|stop|restart|status|uninstall)
	${action}HaProxy
	;;
	*)
	echo "输入错误 !"
	echo "用法: { install | view | set | start | stop | restart | status | uninstall }"
	;;
esac