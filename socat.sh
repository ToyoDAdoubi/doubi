#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: Socat
#	Version: 1.0.5
#	Author: Toyo
#	Blog: https://doub.io/wlzy-18/
#=================================================

sh_ver="1.0.5"
socat_file="/usr/bin/socat"
socat_log_file="/tmp/socat.log"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}" && Error="${Red_font_prefix}[错误]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

Save_iptables(){
	iptables-save > /etc/iptables.up.rules
}
Set_iptables(){
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
}
check_socat(){
	[[ ! -e ${socat_file} ]] && echo -e "${Error} 没有安装Socat，请检查 !" && exit 1
}
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
installSocat(){
	[[ -e ${socat_file} ]] && echo -e "${Error} 已经安装Socat，请检查 !" && exit 1
	apt-get update
	apt-get install -y socat
	Set_iptables
	chmod +x /etc/rc.local
	# echo "nameserver 8.8.8.8" > /etc/resolv.conf
	# echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	socat_exist=`socat -h`
	if [[ ! -e ${socat_file} ]]; then
		echo -e "${Error} 安装Socat失败，请检查 !" && exit 1
	else
		echo -e "${Info} Socat 安装完成 !"
	fi
}
addSocat(){
# 判断是否安装Socat
	check_socat
# 设置本地监听端口
	while true
	do
		echo -e "请输入 Socat 的 本地监听端口 [1-65535]"
		read -e -p "(默认端口: 23333):" Socatport
		[[ -z "$Socatport" ]] && Socatport="23333"
		echo $((${Socatport}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${Socatport} -ge 1 ]] && [[ ${Socatport} -le 65535 ]]; then
				echo
				echo "——————————————————————————————"
				echo -e "	本地监听端口 : ${Red_background_prefix} ${Socatport} ${Font_color_suffix}"
				echo "——————————————————————————————"
				echo
				break
			else
				echo -e "${Error} 请输入正确的数字 !"
			fi
		else
			echo -e "${Error} 请输入正确的数字 !"
		fi
	done
# 设置欲转发端口
	while true
	do
		echo -e "请输入 Socat 远程被转发 端口 [1-65535]"
		read -e -p "(默认端口: ${Socatport}):" Socatport1
		[[ -z "$Socatport1" ]] && Socatport1=${Socatport}
		echo $((${Socatport1}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${Socatport1} -ge 1 ]] && [[ ${Socatport1} -le 65535 ]]; then
				echo
				echo "——————————————————————————————"
				echo -e "	远程转发端口 : ${Red_background_prefix} ${Socatport1} ${Font_color_suffix}"
				echo "——————————————————————————————"
				echo
				break
			else
				echo -e "${Error} 请输入正确的数字 !"
			fi
		else
			echo -e "${Error} 请输入正确的数字 !"
		fi
	done
# 设置欲转发 IP
	read -e -p "请输入 Socat 远程被转发 IP:" socatip
	[[ -z "${socatip}" ]] && echo "取消..." && exit 1
	echo
	echo "——————————————————————————————"
	echo -e "	远程转发 IP : ${Red_background_prefix} ${socatip} ${Font_color_suffix}"
	echo "——————————————————————————————"
	echo
#设置 转发类型
	echo "请输入数字 来选择 Socat 转发类型:"
	echo "1. TCP"
	echo "2. UDP"
	echo "3. TCP+UDP"
	echo
	read -e -p "(默认: TCP+UDP):" socattype_num
	[[ -z "${socattype_num}" ]] && socattype_num="3"
	if [[ ${socattype_num} = "1" ]]; then
		socattype="TCP"
	elif [[ ${socattype_num} = "2" ]]; then
		socattype="UDP"
	elif [[ ${socattype_num} = "3" ]]; then
		socattype="TCP+UDP"
	else
		socattype="TCP+UDP"
	fi
#最后确认
	echo
	echo "——————————————————————————————"
	echo "      请检查 Socat 配置是否有误 !"
	echo
	echo -e "	本地监听端口\t : ${Red_background_prefix} ${Socatport} ${Font_color_suffix}"
	echo -e "	远程转发 IP\t : ${Red_background_prefix} ${socatip} ${Font_color_suffix}"
	echo -e "	远程转发端口\t : ${Red_background_prefix} ${Socatport1} ${Font_color_suffix}"
	echo -e "	转发类型\t : ${Red_background_prefix} ${socattype} ${Font_color_suffix}"
	echo "——————————————————————————————"
	echo
	read -e -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	startSocat
	# 获取IP
	ip=`wget -qO- -t1 -T2 ipinfo.io/ip`
	[[ -z $ip ]] && ip="ip"
	clear
	echo
	echo "——————————————————————————————"
	echo "	Socat 已启动 !"
	echo
	echo -e "	本地监听 IP\t : ${Red_background_prefix} ${ip} ${Font_color_suffix}"
	echo -e "	本地监听端口\t : ${Red_background_prefix} ${Socatport} ${Font_color_suffix}"
	echo
	echo -e "	远程转发 IP\t : ${Red_background_prefix} ${socatip} ${Font_color_suffix}"
	echo -e "	远程转发端口\t : ${Red_background_prefix} ${Socatport1} ${Font_color_suffix}"
	echo -e "	转发类型\t : ${Red_background_prefix} ${socattype} ${Font_color_suffix}"
	echo "——————————————————————————————"
	echo
}
startSocat(){
	if [[ ${socattype} = "TCP" ]]; then
		runSocat "TCP4"
		sleep 2s
		PID=`ps -ef | grep "socat TCP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		[[ -z $PID ]] && echo -e "${Error} Socat TCP 启动失败 !" && exit 1
		addLocal "TCP4"
		iptables -I INPUT -p tcp --dport ${Socatport} -j ACCEPT
	elif [[ ${socattype} = "UDP" ]]; then
		runSocat "UDP4"
		sleep 2s
		PID=`ps -ef | grep "socat UDP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		[[ -z $PID ]] && echo -e "${Error} Socat UDP 启动失败 !" && exit 1
		addLocal "UDP4"
		iptables -I INPUT -p udp --dport ${Socatport} -j ACCEPT
	elif [[ ${socattype} = "TCP+UDP" ]]; then
		runSocat "TCP4"
		runSocat "UDP4"
		sleep 2s
		PID=`ps -ef | grep "socat TCP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		PID1=`ps -ef | grep "socat UDP4-LISTEN:${Socatport}" | grep -v grep | awk '{print $2}'`
		if [[ -z $PID ]]; then
			echo -e "${Error} Socat TCP 启动失败 !" && exit 1
		else
			[[ -z $PID1 ]] && echo -e "${Error} Socat TCP 启动成功，但 UDP 启动失败 !"
			addLocal "TCP4"
			addLocal "UDP4"
			iptables -I INPUT -p tcp --dport ${Socatport} -j ACCEPT
			iptables -I INPUT -p udp --dport ${Socatport} -j ACCEPT
		fi
	fi
	Save_iptables
}
runSocat(){
	nohup socat $1-LISTEN:${Socatport},reuseaddr,fork $1:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &
}
addLocal(){
	sed -i '/exit 0/d' /etc/rc.local
	echo -e "nohup socat $1-LISTEN:${Socatport},reuseaddr,fork $1:${socatip}:${Socatport1} >> ${socat_log_file} 2>&1 &" >> /etc/rc.local
	[[ ${release}  == "debian" ]] && echo -e "exit 0" >> /etc/rc.local
}
# 查看Socat列表
listSocat(){
# 检查是否安装
	check_socat
	socat_total=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | wc -l`
	if [[ ${socat_total} = "0" ]]; then
		echo -e "${Error} 没有发现 Socat 进程运行，请检查 !" && exit 1
	fi
	socat_list_all=""
	for((integer = 1; integer <= ${socat_total}; integer++))
	do
		socat_all=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh"`
		socat_type=`echo -e "${socat_all}" | awk '{print $9}' | sed -n "${integer}p" | cut -c 1-4`
		socat_listen=`echo -e "${socat_all}" | awk '{print $9}' | sed -n "${integer}p" | sed -r 's/.*LISTEN:(.+),reuseaddr.*/\1/'`
		socat_fork=`echo -e "${socat_all}" | awk '{print $10}' | sed -n "${integer}p" | cut -c 6-26`
		socat_pid=`echo -e "${socat_all}" | awk '{print $2}' | sed -n "${integer}p"`
		socat_list_all=${socat_list_all}"${Green_font_prefix}"${integer}". ${Font_color_suffix}进程PID: ${Red_font_prefix}"${socat_pid}"${Font_color_suffix} 类型: ${Red_font_prefix}"${socat_type}"${Font_color_suffix} 监听端口: ${Green_font_prefix}"${socat_listen}"${Font_color_suffix} 转发IP和端口: ${Green_font_prefix}"${socat_fork}"${Font_color_suffix}\n"
	done
	echo
	echo -e "当前有${Green_background_prefix}" ${socat_total} "${Font_color_suffix}个Socat转发进程。"
	echo -e ${socat_list_all}
}
delSocat(){
# 检查是否安装
	check_socat
# 判断进程是否存在
	PID=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $2}'`
	if [[ -z $PID ]]; then
		echo -e "${Error} 没有发现 Socat 进程运行，请检查 !" && exit 1
	fi
	
	while true
	do
	# 列出 Socat
	listSocat
	read -e -p "请输入数字 来选择要终止的 Socat 进程:" stopsocat
	[[ -z "${stopsocat}" ]] && stopsocat="0"
	echo $((${stopsocat}+0)) &>/dev/null
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
			Save_iptables
			socat_total=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | wc -l`
			PID=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | awk '{print $2}' | sed -n "${stopsocat}p"`
			kill -2 ${PID}
			sleep 2s
			socat_total1=$((${socat_total}-1))
			socat_total=`ps -ef | grep socat | grep -v grep | grep -v "socat.sh" | wc -l`
			if [[ ${socat_total} != ${socat_total1} ]]; then
				echo -e "${Error} Socat 停止失败 !" && exit 1
			else
				echo && echo "	Socat 已停止 !" && echo
			fi
			break
		else
			echo -e "${Error} 请输入正确的数字 !"
		fi
	else
		echo "取消..." && exit 1
	fi
	done
}
# 查看日志
tailSocat(){
	[[ ! -e ${socat_log_file} ]] && echo -e "${Error} Socat 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${socat_log_file}${Font_color_suffix} 命令。" && echo
	tail -f ${socat_log_file}
}
uninstallSocat(){
	check_socat
	echo "确定要卸载 Socat ? [y/N]"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=$(ps -ef | grep "socat" | grep -v grep | grep -v ".sh" |awk '{print $2}')
		[[ ! -z "${PID}" ]] && kill -9 "${PID}"
		apt-get remove --purge socat -y
		sed -i "/socat/d" /etc/rc.local
		[[ -e ${socat_file} ]] && echo -e "${Error} Socat 卸载失败，请检查 !" && exit 1
		echo && echo -e "${Info} Socat 已卸载 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/socat.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/socat.sh" && chmod +x socat.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
echo && echo -e "  SoCat 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/wlzy-18 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 SoCat
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 SoCat
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 新增 SoCat
 ${Green_font_prefix}4.${Font_color_suffix} 删除 SoCat
————————————
 ${Green_font_prefix}5.${Font_color_suffix} 查看 SoCat 信息
 ${Green_font_prefix}6.${Font_color_suffix} 查看 SoCat 日志
————————————" && echo
if [[ -e ${socat_file} ]]; then
	echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix}"
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [0-9]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	installSocat
	;;
	2)
	uninstallSocat
	;;
	3)
	addSocat
	;;
	4)
	delSocat
	;;
	5)
	listSocat
	;;
	6)
	tailSocat
	;;
	*)
	echo "请输入正确数字 [0-6]"
	;;
esac