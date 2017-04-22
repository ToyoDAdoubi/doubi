#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Socat
#	Version: 1.0.1
#	Author: Toyo
#	Blog: https://doub.io/wlzy-18/
#=================================================

socat_file="/etc/socat"
socat_log_file="/etc/socat/socat.log"

#检查是否安装Socat
check_socat(){
	socat_exist=`socat -h`
	if [[ ${socat_exist} = "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 没有安装Socat，请检查 !"
		exit 1
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
# 安装Socat
installSocat(){
# 判断是否安装Socat
	socat_exist=`socat -h`
	if [[ ${socat_exist} != "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 已经安装Socat，请检查 !" && exit 1
	fi
check_sys
# 系统判断
	if [[ ${release}  == "centos" ]]; then
		yum update
		yum install -y vim curl socat
	else
		apt-get update
		apt-get install -y vim curl socat
	fi
	chmod +x /etc/rc.local
	#修改DNS为8.8.8.8
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	mkdir ${socat_file}
	#判断socat是否安装成功
	socat_exist=`socat -h`
	if [[ ${socat_exist} = "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 安装Socat失败，请检查 !" && exit 1
	else
		echo -e "\033[42;37m [信息] \033[0m Socat 安装完成 !"
	fi
}
addSocat(){
# 判断是否安装Socat
	check_socat
# 设置本地监听端口
	while true
	do
		echo -e "请输入 Socat 的 本地监听端口 [1-65535]"
		stty erase '^H' && read -p "(默认端口: 23333):" Socatport
		[[ -z "$Socatport" ]] && Socatport="23333"
		expr ${Socatport} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${Socatport} -ge 1 ]] && [[ ${Socatport} -le 65535 ]]; then
				echo
				echo "——————————————————————————————"
				echo -e "	本地监听端口 : \033[41;37m ${Socatport} \033[0m"
				echo "——————————————————————————————"
				echo
				break
			else
				echo -e "\033[41;37m [错误] \033[0m 请输入正确的数字 !"
			fi
		else
			echo -e "\033[41;37m [错误] \033[0m 请输入正确的数字 !"
		fi
	done
# 设置欲转发端口
	while true
	do
		echo -e "请输入 Socat 欲转发的 端口 [1-65535]"
		stty erase '^H' && read -p "(默认端口: ${Socatport}):" Socatport1
		[[ -z "$Socatport1" ]] && Socatport1=${Socatport}
		expr ${Socatport1} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${Socatport1} -ge 1 ]] && [[ ${Socatport1} -le 65535 ]]; then
				echo
				echo "——————————————————————————————"
				echo -e "	欲转发端口 : \033[41;37m ${Socatport1} \033[0m"
				echo "——————————————————————————————"
				echo
				break
			else
				echo -e "\033[41;37m [错误] \033[0m 请输入正确的数字 !"
			fi
		else
			echo -e "\033[41;37m [错误] \033[0m 请输入正确的数字 !"
		fi
	done
# 设置欲转发 IP
	stty erase '^H' && read -p "请输入 Socat 欲转发的 IP:" socatip
	[[ -z "${socatip}" ]] && echo "取消..." && exit 1
	echo
	echo "——————————————————————————————"
	echo -e "	欲转发 IP : \033[41;37m ${socatip} \033[0m"
	echo "——————————————————————————————"
	echo
#设置 转发类型
	echo "请输入数字 来选择 Socat 转发类型:"
	echo "1. TCP"
	echo "2. UDP"
	echo "3. TCP+UDP"
	echo
	stty erase '^H' && read -p "(默认: TCP+UDP):" socattype_num
	[ -z "${socattype_num}" ] && socattype_num="3"
	if [ ${socattype_num} = "1" ]; then
		socattype="TCP"
	elif [ ${socattype_num} = "2" ]; then
		socattype="UDP"
	elif [ ${socattype_num} = "3" ]; then
		socattype="TCP+UDP"
	else
		socattype="TCP+UDP"
	fi
#最后确认
	echo
	echo "——————————————————————————————"
	echo "      请检查 Socat 配置是否有误 !"
	echo
	echo -e "	本地监听端口 : \033[41;37m ${Socatport} \033[0m"
	echo -e "	欲转发 IP : \033[41;37m ${socatip} \033[0m"
	echo -e "	欲转发端口 : \033[41;37m ${Socatport1} \033[0m"
	echo -e "	转发类型 : \033[41;37m ${socattype} \033[0m"
	echo "——————————————————————————————"
	echo
	stty erase '^H' && read -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	
	if [ ${socattype} = "TCP" ]; then
		nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &
		sleep 2s
		PID=`ps -ef | grep "socat TCP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		if [[ -z $PID ]]; then
			echo -e "\033[41;37m [错误] \033[0m Socat TCP 启动失败 !" && exit 1
		fi
# 系统判断
		check_sys
		if [[ ${release}  == "debian" ]]; then
			sed -i '$d' /etc/rc.local
			echo -e "nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
			echo -e "exit 0" >> /etc/rc.local
		else
			echo -e "nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
		fi
		iptables -I INPUT -p tcp --dport ${Socatport} -j ACCEPT
	elif [ ${socattype} = "UDP" ]; then
		nohup socat UDP4-LISTEN:${Socatport},reuseaddr,fork UDP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &
		sleep 2s
		PID=`ps -ef | grep "socat UDP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		if [[ -z $PID ]]; then
			echo -e "\033[41;37m [错误] \033[0m Socat UDP 启动失败 !" && exit 1
		fi
# 系统判断
		check_sys
		if [[ ${release}  == "debian" ]]; then
			sed -i '$d' /etc/rc.local
			echo -e "nohup socat UDP4-LISTEN:${Socatport},reuseaddr,fork UDP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
			echo -e "exit 0" >> /etc/rc.local
		else
			echo -e "nohup socat UDP4-LISTEN:${Socatport},reuseaddr,fork UDP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
		fi
		iptables -I INPUT -p udp --dport ${Socatport} -j ACCEPT
	elif [ ${socattype} = "TCP+UDP" ]; then
		nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &
		nohup socat UDP4-LISTEN:${Socatport},reuseaddr,fork UDP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &
		sleep 2s
		PID=`ps -ef | grep "socat TCP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		PID1=`ps -ef | grep "socat UDP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		if [[ -z $PID ]]; then
			echo -e "\033[41;37m [错误] \033[0m Socat TCP 启动失败 !"
			exit 1
		else
			if [[ -z $PID ]]; then
				echo -e "\033[41;37m [错误] \033[0m Socat TCP 启动成功，但 UDP 启动失败 !"
# 系统判断
				check_sys
				if [[ ${release}  == "debian" ]]; then
					sed -i '$d' /etc/rc.local
					echo -e "nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
					echo -e "exit 0" >> /etc/rc.local
				else
					echo -e "nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
				fi
				exit 1
				iptables -I INPUT -p tcp --dport ${Socatport} -j ACCEPT
			fi
# 系统判断
			check_sys
			if [[ ${release}  == "debian" ]]; then
				sed -i '$d' /etc/rc.local
				echo -e "nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
				echo -e "nohup socat UDP4-LISTEN:${Socatport},reuseaddr,fork UDP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
				echo -e "exit 0" >> /etc/rc.local
			else
				echo -e "nohup socat TCP4-LISTEN:${Socatport},reuseaddr,fork TCP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
				echo -e "nohup socat UDP4-LISTEN:${Socatport},reuseaddr,fork UDP4:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
			fi
			iptables -I INPUT -p tcp --dport ${Socatport} -j ACCEPT
			iptables -I INPUT -p udp --dport ${Socatport} -j ACCEPT
		fi
	fi
# 获取IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	if [[ -z $ip ]]; then
		ip="ip"
	fi
	clear
	echo
	echo "——————————————————————————————"
	echo "	Socat 已启动 !"
	echo
	echo -e "	本地 IP : \033[41;37m ${ip} \033[0m"
	echo -e "	本地监听端口 : \033[41;37m ${Socatport} \033[0m"
	echo
	echo -e "	欲转发 IP : \033[41;37m ${socatip} \033[0m"
	echo -e "	欲转发端口 : \033[41;37m ${Socatport1} \033[0m"
	echo -e "	转发类型 : \033[41;37m ${socattype} \033[0m"
	echo "——————————————————————————————"
	echo
}
# 查看Socat列表
listSocat(){
# 检查是否安装
	check_socat
	socat_total=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | wc -l`
	if [[ ${socat_total} = "0" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 没有发现 Socat 进程运行，请检查 !"
		exit 1
	fi
	socat_list_all=""
	for((integer = 1; integer <= ${socat_total}; integer++))
	do
		socat_all=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh"`
		socat_type=`echo -e "${socat_all}" | awk '{print $9}' | sed -n "${integer}p" | cut -c 1-4`
		socat_listen=`echo -e "${socat_all}" | awk '{print $9}' | sed -n "${integer}p" | sed -r 's/.*LISTEN:(.+),reuseaddr.*/\1/'`
		socat_fork=`echo -e "${socat_all}" | awk '{print $10}' | sed -n "${integer}p" | cut -c 6-26`
		socat_pid=`echo -e "${socat_all}" | awk '{print $2}' | sed -n "${integer}p"`
		socat_list_all=${socat_list_all}${integer}". 进程PID: "${socat_pid}" 类型: "${socat_type}" 监听端口: "${socat_listen}" 转发IP和端口: "${socat_fork}"\n"
	done
	echo
	echo -e "当前有 \033[42;37m "${socat_total}" \033[0m 个Socat转发进程。"
	echo -e ${socat_list_all}
}
delSocat(){
# 检查是否安装
	check_socat
# 判断进程是否存在
	PID=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $2}'`
	if [[ -z $PID ]]; then
		echo -e "\033[41;37m [错误] \033[0m 没有发现 Socat 进程运行，请检查 !" && exit 1
	fi
	
	while true
	do
	# 列出 Socat
	listSocat
	stty erase '^H' && read -p "请输入数字 来选择要终止的 Socat 进程:" stopsocat
	[[ -z "${stopsocat}" ]] && stopsocat="0"
	expr ${stopsocat} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${stopsocat} -ge 1 ]] && [[ ${stopsocat} -le ${socat_total} ]]; then
			# 删除开机启动
			socat_del_rc1=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $8}' | sed -n "${stopsocat}p"`
			socat_del_rc2=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $9}' | sed -n "${stopsocat}p"`
			socat_del_rc3=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $10}' | sed -n "${stopsocat}p"`
			socat_del_rc4=${socat_del_rc1}" "${socat_del_rc2}" "${socat_del_rc3}
			#echo ${socat_del_rc4}
			sed -i "/${socat_del_rc4}/d" /etc/rc.local
			# 删除防火墙规则
			socat_listen=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $9}' | sed -n "${stopsocat}p" | sed -r 's/.*LISTEN:(.+),reuseaddr.*/\1/'`
			socat_type=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $9}' | sed -n "${stopsocat}p" | cut -c 1-4`
			if [[ ${socat_type} = "TCP4" ]]; then
				iptables -D INPUT -p tcp --dport ${socat_listen} -j ACCEPT
			else
				iptables -D INPUT -p udp --dport ${socat_listen} -j ACCEPT
			fi
			
			socat_total=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | wc -l`
			PID=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $2}' | sed -n "${stopsocat}p"`
			kill -2 ${PID}
			sleep 2s
			socat_total1=$[ $socat_total - 1 ]
			socat_total=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | wc -l`
			if [[ ${socat_total} != ${socat_total1} ]]; then
				echo -e "\033[41;37m [错误] \033[0m Socat 停止失败 !" && exit 1
			else
				echo && echo "	Socat 已停止 !" && echo
			fi
			break
		else
			echo -e "\033[41;37m [错误] \033[0m 请输入正确的数字 !"
		fi
	else
		echo "取消..." && exit 1
	fi
	done
}
# 查看日志
tailSocat(){
# 判断日志是否存在
	if [[ ! -e ${socat_log_file} ]]; then
		echo -e "\033[41;37m [错误] \033[0m Socat 日志文件不存在 !" && exit 1
	else
		tail -f ${socat_log_file}
	fi
}
uninstallSocat(){
# 检查是否安装
	check_socat

	echo "确定要卸载 Socat ? [y/N]"
	stty erase '^H' && read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_sys
		# 系统判断
		if [[ ${release}  == "centos" ]]; then
			yum remove socat -y
		else
			apt-get remove --purge socat -y
		fi
		rm -rf ${socat_file}
		socat_exist=`socat -h`
		if [[ ${socat_exist} != "" ]]; then
			echo -e "\033[41;37m [错误] \033[0m Socat卸载失败，请检查 !" && exit 1
		fi
		echo && echo "	Socat 已卸载 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}

action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|add|del|list|tail|uninstall)
	${action}Socat
	;;
	*)
	echo "输入错误 !"
	echo "用法: {install | add | del | list | tail | uninstall}"
	;;
esac