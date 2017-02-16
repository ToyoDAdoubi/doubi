#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: iptables Port forwarding
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/wlzy-20/
#=================================================

#检查是否安装iptables
check_iptables(){
	iptables_exist=`iptables -V`
	if [[ ${iptables_exist} = "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 没有安装iptables，请检查 !"
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
# 安装iptables
installiptables(){
# 判断是否安装iptables
	iptables_exist=`iptables -V`
	if [[ ${iptables_exist} != "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 已经安装iptables，请检查 !"
		exit 1
	fi
check_sys
# 系统判断
	if [[ ${release}  == "centos" ]]; then
		yum update
		yum install -y vim curl iptables
	else
		apt-get update
		apt-get install -y vim curl iptables
	fi
	chmod +x /etc/rc.local
	echo 1 > /proc/sys/net/ipv4/ip_forward
	#判断iptables是否安装成功
	iptables_exist=`iptables -V`
	if [[ ${iptables_exist} = "" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 安装iptables失败，请检查 !"
		exit 1
	else
		echo -e "\033[42;37m [信息] \033[0m iptables 安装/升级 完成 !"
	fi
}
addiptables(){
# 判断是否安装iptables
	check_iptables
# 设置本地监听端口
	read -p "请输入 iptables 的 本地监听端口 [1-65535](支持端口段: 2333-6666): " iptablesport
	[[ -z "${iptablesport}" ]] && echo "取消..." && exit 1
# 设置欲转发端口
	echo -e "请输入 iptables 欲转发的 端口 [1-65535](支持端口段: 2333-6666): "
	read -p "(默认端口: ${iptablesport})" iptablesport1
	[[ -z "${iptablesport1}" ]] && iptablesport1=${iptablesport}
# 设置欲转发 IP
	read -p "请输入 iptables 欲转发的 IP:" iptablesip
	[[ -z "${iptablesip}" ]] && echo "取消..." && exit 1
# 设置本地 IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	if [[ -z $ip ]]; then
		read -p "无法检测到本服务器的公网IP，请输入本服务器的 公网IP:" ip
		[[ -z "${ip}" ]] && echo "取消..." && exit 1
	fi
#设置 转发类型
	echo "请输入数字 来选择 iptables 转发类型:"
	echo "1. TCP"
	echo "2. UDP"
	echo "3. TCP+UDP"
	echo
	read -p "(默认: TCP+UDP):" iptablestype_num
	[ -z "${iptablestype_num}" ] && iptablestype_num="3"
	if [ ${iptablestype_num} = "1" ]; then
		iptablestype="TCP"
	elif [ ${iptablestype_num} = "2" ]; then
		iptablestype="UDP"
	elif [ ${iptablestype_num} = "3" ]; then
		iptablestype="TCP+UDP"
	else
		iptablestype="TCP+UDP"
	fi
#最后确认
	echo
	echo "——————————————————————————————"
	echo "      请检查 iptables 端口转发规则配置是否有误 !"
	echo
	echo -e "	本地监听端口 : \033[41;37m ${iptablesport} \033[0m"
	echo -e "	欲转发端口    : \033[41;37m ${iptablesport1} \033[0m"
	echo -e "	欲转发 IP : \033[41;37m ${iptablesip} \033[0m"
	echo -e "	公网    IP : \033[41;37m ${ip} \033[0m"
	echo -e "	转发类型 : \033[41;37m ${iptablestype} \033[0m"
	echo "——————————————————————————————"
	echo
	read -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	
	echo 1 > /proc/sys/net/ipv4/ip_forward
	
	iptablesport2=`echo ${iptablesport} | sed 's/-/:/g'`
	iptablesport3=`echo ${iptablesport1} | sed 's/-/:/g'`
	
	if [ ${iptablestype} = "TCP" ]; then
		iptables -t nat -A PREROUTING -p tcp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
		iptables -t nat -A POSTROUTING -p tcp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}
		sleep 1s
# 系统判断
		check_sys
		# 加入开机启动
		if [[ ${release}  == "debian" ]]; then
			sed -i '$d' /etc/rc.local
			echo -e "iptables -t nat -A PREROUTING -p tcp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A POSTROUTING -p tcp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}" >> /etc/rc.local
			echo -e "exit 0" >> /etc/rc.local
		else
			echo -e "iptables -t nat -A PREROUTING -p tcp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A POSTROUTING -p tcp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}" >> /etc/rc.local
		fi
		# 开放防火墙端口
		iptables -I INPUT -p tcp --dport ${iptablesport2} -j ACCEPT
		service iptables save
		service iptables restart
	elif [ ${iptablestype} = "UDP" ]; then
		iptables -t nat -A PREROUTING -p udp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
		iptables -t nat -A POSTROUTING -p udp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}
		sleep 1s
# 系统判断
		check_sys
		# 加入开机启动
		if [[ ${release}  == "debian" ]]; then
			sed -i '$d' /etc/rc.local
			echo -e "iptables -t nat -A PREROUTING -p udp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A POSTROUTING -p udp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}" >> /etc/rc.local
			echo -e "exit 0" >> /etc/rc.local
		else
			echo -e "iptables -t nat -A PREROUTING -p udp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A POSTROUTING -p udp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}" >> /etc/rc.local
		fi
		# 开放防火墙端口
		iptables -I INPUT -p udp --dport ${iptablesport2} -j ACCEPT
		service iptables save
		service iptables restart
	elif [ ${iptablestype} = "TCP+UDP" ]; then
		iptables -t nat -A PREROUTING -p tcp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
		iptables -t nat -A PREROUTING -p udp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
		iptables -t nat -A POSTROUTING -p tcp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}
		iptables -t nat -A POSTROUTING -p udp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}
		sleep 1s
# 系统判断
		check_sys
		# 加入开机启动
		if [[ ${release}  == "debian" ]]; then
			sed -i '$d' /etc/rc.local
			echo -e "iptables -t nat -A PREROUTING -p tcp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A PREROUTING -p udp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A POSTROUTING -p tcp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}
iptables -t nat -A POSTROUTING -p udp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}" >> /etc/rc.local
			echo -e "exit 0" >> /etc/rc.local
		else
			echo -e "iptables -t nat -A PREROUTING -p tcp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A PREROUTING -p udp --dport ${iptablesport2} -j DNAT --to-destination ${iptablesip}:${iptablesport1}
iptables -t nat -A POSTROUTING -p tcp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}
iptables -t nat -A POSTROUTING -p udp -d ${iptablesip} --dport ${iptablesport3} -j SNAT --to-source ${ip}" >> /etc/rc.local
		fi
		# 开放防火墙端口
		iptables -I INPUT -p tcp --dport ${iptablesport2} -j ACCEPT
		iptables -I INPUT -p udp --dport ${iptablesport2} -j ACCEPT
		service iptables save
		service iptables restart
	fi
	clear
	echo
	echo "——————————————————————————————"
	echo "	iptables 端口转发规则配置完成 !"
	echo
	echo -e "	本地 IP : \033[41;37m ${ip} \033[0m"
	echo -e "	本地监听端口 : \033[41;37m ${iptablesport} \033[0m"
	echo
	echo -e "	欲转发 IP : \033[41;37m ${iptablesip} \033[0m"
	echo -e "	欲转发端口 : \033[41;37m ${iptablesport1} \033[0m"
	echo -e "	转发类型 : \033[41;37m ${iptablestype} \033[0m"
	echo "——————————————————————————————"
	echo
}
# 查看iptables列表
listiptables(){
# 检查是否安装
	check_iptables
	iptables_total=`iptables -t nat -vnL PREROUTING | wc -l`
	iptables_total=$[ $iptables_total - 2 ]
	if [[ ${iptables_total} = "0" ]]; then
		echo -e "\033[41;37m [错误] \033[0m 没有发现 iptables 端口转发规则，请检查 !"
		exit 1
	fi
	iptables_list_all=""
	for((integer = 1; integer <= ${iptables_total}; integer++))
	do
		iptables_type=`iptables -t nat -vnL PREROUTING | awk '{print $4}' | sed "1,2d" | sed -n "${integer}p"`
		iptables_listen=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "${integer}p" | awk -F "dpt:" '{print $2}'`
		[[ -z ${iptables_listen} ]] && iptables_listen=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "${integer}p" | awk -F "dpts:" '{print $2}'`
		iptables_fork=`iptables -t nat -vnL PREROUTING | awk '{print $12}' | sed "1,2d" | sed -n "${integer}p" | awk -F "to:" '{print $2}'`
		iptables_list_all=${iptables_list_all}${integer}". 类型: "${iptables_type}" 监听端口: "${iptables_listen}" 转发IP和端口: "${iptables_fork}"\n"
	done
	echo
	echo -e "当前有 \033[42;37m "${iptables_total}" \033[0m 个 iptables 端口转发规则。"
	echo -e ${iptables_list_all}
}
deliptables(){
# 检查是否安装
	check_iptables	
	
	while true
	do
	# 列出 iptables
	listiptables
	read -p "请输入数字 来选择要删除的 iptables 端口转发规则:" stopiptables
	[[ -z "${stopiptables}" ]] && stopiptables="0"
	expr ${stopiptables} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${stopiptables} -ge 1 ]] && [[ ${stopiptables} -le ${iptables_total} ]]; then
			# 删除开机启动
			iptables_type_del=`iptables -t nat -vnL PREROUTING | awk '{print $4}' | sed "1,2d" | sed -n "${stopiptables}p"`
			iptables_listen_del=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "${stopiptables}p" | awk -F "dpt:" '{print $2}'`
			[[ -z ${iptables_listen_del} ]] && iptables_listen_del=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "${stopiptables}p" | awk -F "dpts:" '{print $2}'`
			iptables_fork_del=`iptables -t nat -vnL PREROUTING | awk '{print $12}' | sed "1,2d" | sed -n "${stopiptables}p" | awk -F "to:" '{print $2}'`
			if [[ ${iptables_type_del} = "tcp" ]]; then
				iptables_del_tcp_1=`echo "iptables -t nat -A PREROUTING -p tcp --dport ${iptables_listen_del} -j DNAT --to-destination ${iptables_fork_del}"`
				iptables_del_tcp_1_ip=`echo ${iptables_fork_del} | awk -F ":" '{print $1}'`
				iptables_del_tcp_1_prot=`echo ${iptables_fork_del} | awk -F ":" '{print $2}'`
				iptables_del_tcp_1_prot=`echo ${iptables_del_tcp_1_prot} | sed 's/-/:/g'`
				iptables_del_tcp_2=`echo "iptables -t nat -A POSTROUTING -p tcp -d ${iptables_del_tcp_1_ip} --dport ${iptables_del_tcp_1_prot} -j SNAT"`
				#echo ${iptables_del_tcp_2}
				sed -i "/${iptables_del_tcp_1}/d" /etc/rc.local
				sed -i "/${iptables_del_tcp_2}/d" /etc/rc.local
			else
				iptables_del_udp_1=`echo "iptables -t nat -A PREROUTING -p udp --dport ${iptables_listen_del} -j DNAT --to-destination ${iptables_fork_del}"`
				iptables_del_udp_1_ip=`echo ${iptables_fork_del} | awk -F ":" '{print $1}'`
				iptables_del_udp_1_prot=`echo ${iptables_fork_del} | awk -F ":" '{print $2}'`
				iptables_del_udp_1_prot=`echo ${iptables_del_udp_1_prot} | sed 's/-/:/g'`
				iptables_del_udp_2=`echo "iptables -t nat -A POSTROUTING -p udp -d ${iptables_del_udp_1_ip} --dport ${iptables_del_udp_1_prot} -j SNAT"`
				#echo ${iptables_del_udp_2}
				sed -i "/${iptables_del_udp_1}/d" /etc/rc.local
				sed -i "/${iptables_del_udp_2}/d" /etc/rc.local
			fi
			
			# 删除端口开放的防火墙规则
			iptables_listen_del_2=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "${stopiptables}p" | awk -F "dpt:" '{print $2}'`
			[[ -z ${iptables_listen_del_2} ]] && iptables_listen_del_2=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "${stopiptables}p" | awk -F "dpts:" '{print $2}'`
			iptables_type_del_2=`iptables -t nat -vnL PREROUTING | awk '{print $4}' | sed "1,2d" | sed -n "${stopiptables}p"`
			if [[ ${iptables_type_del_2} = "tcp" ]]; then
				iptables -D INPUT -p tcp --dport ${iptables_listen_del_2} -j ACCEPT
			else
				iptables -D INPUT -p udp --dport ${iptables_listen_del_2} -j ACCEPT
			fi
			service iptables save
			service iptables restart
		
			iptables_total=`iptables -t nat -vnL PREROUTING | wc -l`
			iptables_total=$[ $iptables_total - 2 ]
			iptables_total1=$[ $iptables_total - 1 ]
			
			iptables -t nat -D POSTROUTING ${stopiptables}
			iptables -t nat -D PREROUTING ${stopiptables}
			sleep 1s
			iptables_total=`iptables -t nat -vnL PREROUTING | wc -l`
			iptables_total=$[ $iptables_total - 2 ]
			#echo ${iptables_total}"+"${iptables_total1}
			if [[ ${iptables_total} != ${iptables_total1} ]]; then
				echo -e "\033[41;37m [错误] \033[0m iptables 端口转发规则 删除失败 !"
				exit 1
			else
				echo
				echo "	iptables 端口转发规则已删除 !"
				echo
			fi
			break
		else
			echo -e "\033[41;37m [错误] \033[0m 请输入正确的数字 !"
		fi
	else
		echo "取消..."
		exit 1
	fi
	done
}
uninstalliptables(){
# 检查是否安装
	check_iptables

	printf "确定要清空 iptables 所有端口转发规则 ? (y/N)"
	printf "\n"
	read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		iptables_total=`iptables -t nat -vnL PREROUTING | wc -l`
		iptables_total=$[ $iptables_total - 2 ]
		for((integer = 1; integer <= ${iptables_total}; integer++))
		do
			iptables_fork_del_3=`iptables -t nat -vnL PREROUTING | awk '{print $12}' | sed "1,2d" | sed -n "1p" | awk -F "to:" '{print $2}'`
			iptables_listen_del_3=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "1p" | awk -F "dpt:" '{print $2}'`
			[[ -z ${iptables_listen_del_3} ]] && iptables_listen_del_3=`iptables -t nat -vnL PREROUTING | awk '{print $11}' | sed "1,2d" | sed -n "1p" | awk -F "dpts:" '{print $2}'`
			iptables_type_del_3=`iptables -t nat -vnL PREROUTING | awk '{print $4}' | sed "1,2d" | sed -n "1p"`
			if [[ ${iptables_type_del_3} = "tcp" ]]; then
				iptables_del_tcp_1=`echo "iptables -t nat -A PREROUTING -p tcp --dport ${iptables_listen_del_3} -j DNAT --to-destination ${iptables_fork_del_3}"`
				iptables_del_tcp_1_ip=`echo ${iptables_fork_del_3} | awk -F ":" '{print $1}'`
				iptables_del_tcp_1_prot=`echo ${iptables_fork_del_3} | awk -F ":" '{print $2}'`
				iptables_del_tcp_1_prot=`echo ${iptables_del_tcp_1_prot} | sed 's/-/:/g'`
				iptables_del_tcp_2=`echo "iptables -t nat -A POSTROUTING -p tcp -d ${iptables_del_tcp_1_ip} --dport ${iptables_del_tcp_1_prot} -j SNAT"`
				sed -i "/${iptables_del_tcp_1}/d" /etc/rc.local
				sed -i "/${iptables_del_tcp_2}/d" /etc/rc.local
				
				iptables -D INPUT -p tcp --dport ${iptables_listen_del_3} -j ACCEPT
			else
				iptables_del_udp_1=`echo "iptables -t nat -A PREROUTING -p udp --dport ${iptables_listen_del_3} -j DNAT --to-destination ${iptables_fork_del_3}"`
				iptables_del_udp_1_ip=`echo ${iptables_fork_del_3} | awk -F ":" '{print $1}'`
				iptables_del_udp_1_prot=`echo ${iptables_fork_del_3} | awk -F ":" '{print $2}'`
				iptables_del_udp_1_prot=`echo ${iptables_del_udp_1_prot} | sed 's/-/:/g'`
				iptables_del_udp_2=`echo "iptables -t nat -A POSTROUTING -p udp -d ${iptables_del_udp_1_ip} --dport ${iptables_del_udp_1_prot} -j SNAT"`
				sed -i "/${iptables_del_udp_1}/d" /etc/rc.local
				sed -i "/${iptables_del_udp_2}/d" /etc/rc.local
				
				iptables -D INPUT -p udp --dport ${iptables_listen_del_3} -j ACCEPT
			fi
			
			iptables -t nat -D POSTROUTING 1
			iptables -t nat -D PREROUTING 1
			sleep 1s
		done
		service iptables save
		service iptables restart
		
		echo
		echo "	iptables 已清空 所有端口转发规则 !"
		echo
	else
		echo
		echo "清空已取消..."
		echo
	fi
}

action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|add|del|list|uninstall)
	${action}iptables
	;;
	*)
	echo "输入错误 !"
	echo "用法: {install | add | del | list | uninstall}"
	;;
esac