#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: SSH modify port
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/linux-jc11/
#=================================================

sh_ver="1.0.0"
CONF="/etc/ssh/sshd_config"
SSH_init_1="/etc/init.d/ssh"
SSH_init_2="/etc/init.d/sshd"
if [[ -e ${SSH_init_1} ]]; then
	SSH_init=${SSH_init_1}
elif [[ -e ${SSH_init_2} ]]; then
	SSH_init=${SSH_init_2}
else
	echo -e "${Error} 找不到 SSH 的服务脚本文件！" && exit 1
fi
bak_text="（可通过备份SSH配置文件复原：[ ${Green_font_prefix}rm -rf /etc/ssh/sshd_config && mv /etc/ssh/sshd_config.bak /etc/ssh/sshd_config && ${SSH_init} restart${Font_color_suffix} ]）"
over_text="${Tip} 当服务器存在外部防火墙时（如 阿里云、腾讯云、微软云、谷歌云、亚马逊云等），需要外部防火墙开放 新SSH端口TCP协议方可连接！(如使用途中出现任何问题均可通过该代码复原：[ ${Green_font_prefix}rm -rf /etc/ssh/sshd_config && mv /etc/ssh/sshd_config.bak /etc/ssh/sshd_config && ${SSH_init} restart${Font_color_suffix} ] )"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}" && Error="${Red_font_prefix}[错误]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')

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
check_installed_status(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} SSH配置文件不存在[ ${CONF} ]，请检查 !" && exit 1
}
check_pid(){
	PID=$(ps -ef| grep '/usr/sbin/sshd'| grep -v grep| awk '{print $2}')
}
Read_config(){
	port_all=$(cat ${CONF}|grep -v '#'|grep "Port "|awk '{print $2}')
	if [[ -z ${port_all} ]]; then
		port=22
	else
		port=${port_all}
	fi
}
Set_port(){
	while true
		do
		echo -e "\n旧SSH端口：${Green_font_prefix}[${port}]${Font_color_suffix}"
		echo -e "请输入新的SSH端口 [1-65535]"
		read -e -p "(输入为空则取消):" new_port
		[[ -z "${new_port}" ]] && echo "取消..." && exit 1
		echo $((${new_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${new_port} -ge 1 ]] && [[ ${new_port} -le 65535 ]]; then
				if [[ ${new_port} == ${port} ]]; then
					echo -e "输入错误, 新端口与旧端口一致。"
				else
					echo && echo "============================="
					echo -e "	新端口 : ${Red_background_prefix} ${new_port} ${Font_color_suffix}"
					echo "=============================" && echo
					break
				fi
			else
				echo -e "输入错误, 请输入正确的端口。"
			fi
		else
			echo -e "输入错误, 请输入正确的端口。"
		fi
	done
}
choose_the_way(){
	echo -e "请选择SSH端口修改方式：
 1. 直接修改（直接修改旧端口为新端口，并且防火墙禁止旧端口 开放新端口）
 2. 保守修改（不删除旧端口，先添加新端口，然后手动断开SSH链接并使用新端口尝试链接，如果链接正常，那么再次执行脚本删除旧端口配置）\n
 一般来说修改SSH端口不会出现什么问题，但保守起见，我做了两个修改方式。
 如果不懂请选 ${Green_font_prefix}[2. 保守修改]${Font_color_suffix}，避免因为未知问题而导致修改后无法通过 新端口和旧端口 链接服务器！\n
 ${over_text}\n"
	read -e -p "(默认: 2. 保守修改):" choose_the_way_num
	[[ -z "${choose_the_way_num}" ]] && choose_the_way_num="2"
	if [[ ${choose_the_way_num} == "1" ]]; then
		cp -f "${CONF}" "/etc/ssh/sshd_config.bak"
		Direct_modification
	elif [[ ${choose_the_way_num} == "2" ]]; then
		cp -f "${CONF}" "/etc/ssh/sshd_config.bak"
		Conservative_modifications
	else
		echo -e "${Error} 请输入正确的数字 [1-2]" && exit 1
	fi
}
Direct_modification(){
	echo -e "${Info} 删除旧端口配置..."
	sed -i "/Port ${port}/d" "${CONF}"
	echo -e "${Info} 添加新端口配置..."
	echo -e "\nPort ${new_port}" >> "${CONF}"
	${SSH_init} restart
	sleep 2s
	check_pid
	if [[ -z ${PID} ]]; then
			echo -e "${Error} SSH 启动失败 !${bak_text}" && exit 1
		else
			port_status=$(netstat -lntp|grep ssh|awk '{print $4}'|grep -w "${new_port}")
			if [[ -z ${port_status} ]]; then
				echo -e "${Error} SSH 端口修改失败 !${bak_text}" && exit 1
			else
				Del_iptables_ACCEPT
				Del_iptables_DROP
				Add_iptables_ACCEPT
				Add_iptables_DROP
				Set_iptables
				#rm -rf /etc/ssh/sshd_config.bak
				echo -e "${Info} SSH 端口修改成功！新端口：[${Green_font_prefix}${new_port}${Font_color_suffix}]"
				echo -e "${over_text}"
			fi
		fi
}
Conservative_modifications(){
	if [[ $1 != "End" ]]; then
		echo -e "${Info} 添加新端口配置..."
		echo -e "\nPort ${new_port}" >> "${CONF}"
		${SSH_init} restart
		sleep 2s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} SSH 启动失败 !${bak_text}" && exit 1
		else
			port_status=$(netstat -lntp|grep ssh|awk '{print $4}'|grep -w "${new_port}")
			if [[ -z ${port_status} ]]; then
				echo -e "${Error} SSH 端口添加失败 !${bak_text}" && exit 1
			else
				Add_iptables_ACCEPT
				Set_iptables
				echo "${new_port}|${port}" > "${file}/ssh_port.conf"
				echo -e "${Info} SSH 端口添加成功 ! 
请手动断开 SSH链接并使用新端口 ${Green_font_prefix}[${new_port}]${Font_color_suffix} 尝试链接，如无法链接 请通过旧端口 ${Green_font_prefix}[${port}]${Font_color_suffix} 链接，如链接正常 请链接后再次执行脚本${Green_font_prefix} [bash ${file}/ssh_port.sh end]${Font_color_suffix} 以删除旧端口配置！"
				echo -e "${over_text}"
			fi
		fi
	else
		[[ ! -e "${file}/ssh_port.conf" ]] && echo -e "${Error} ${file}/ssh_port.conf 文件缺失 !" && exit 1
		new_port=$(cat "${file}/ssh_port.conf"|awk -F '|' '{print $1}')
		port=$(cat "${file}/ssh_port.conf"|awk -F '|' '{print $2}')
		rm -rf "${file}/ssh_port.conf"
		echo -e "${Info} 删除旧端口配置..."
		sed -i "/Port ${port}/d" "${CONF}"
		${SSH_init} restart
		sleep 2s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} SSH 启动失败 !" && exit 1
		else
			Add_iptables_DROP
			Set_iptables
			#rm -rf /etc/ssh/sshd_config.bak
			echo -e "${Info} 所有配置完成！新端口：[${Green_font_prefix}${new_port}${Font_color_suffix}]"
			echo -e "${over_text}"
		fi
	fi
}
modify_ssh(){
	Read_config
	Set_port
	choose_the_way
}
end_ssh(){
	Conservative_modifications "End"
}
Add_iptables_ACCEPT(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j ACCEPT
}
Del_iptables_ACCEPT(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
}
Add_iptables_DROP(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j DROP
}
Del_iptables_DROP(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j DROP
}
Set_iptables(){
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
check_installed_status
action=$1
[[ -z $1 ]] && action=modify
case "$action" in
    modify|end)
    ${action}_ssh
    ;;
    *)
    echo "输入错误 !"
    echo "用法: {modify|end}"
    ;;
esac