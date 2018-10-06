#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: tinyPortMapper
#	Version: 1.0.2
#	Author: Toyo
#	Blog: https://doub.io/wlzy-36/
#=================================================
sh_ver="1.0.2"

Folder="/usr/local/tinyPortMapper"
File="/usr/local/tinyPortMapper/tinymapper"
LOG_File="/tmp/tinymapper.log"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}" && Error="${Red_font_prefix}[错误]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

Get_IP(){
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
}
Add_iptables(){
	iptables_Type=$1
	if [[ ! -z "${local_Port}" ]]; then
		if [[ ${iptables_Type} == "tcp" ]]; then
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${local_Port} -j ACCEPT
		elif [[ ${iptables_Type} == "udp" ]]; then
			iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${local_Port} -j ACCEPT
		elif [[ ${iptables_Type} == "all" ]]; then
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${local_Port} -j ACCEPT
			iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${local_Port} -j ACCEPT
		fi
	fi
}
Del_iptables(){
	iptables_Type=$1
	if [[ ! -z "${port}" ]]; then
		if [[ ${iptables_Type} == "tcp" ]]; then
			iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		elif [[ ${iptables_Type} == "udp" ]]; then
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		elif [[ ${iptables_Type} == "all" ]]; then
			iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		fi
	fi
}
Save_iptables(){
	iptables-save > /etc/iptables.up.rules
}
Set_iptables(){
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
}
check_tinyPortMapper(){
	[[ ! -e ${File} ]] && echo -e "${Error} 没有安装 tinyPortMapper , 请检查 !" && exit 1
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
	bit=`uname -m`
}
check_new_ver(){
	tinymapper_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/wangyu-/tinyPortMapper/releases | grep -o '"tag_name": ".*"' |grep -v '20180620.0'|head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
	if [[ -z ${tinymapper_new_ver} ]]; then
		echo -e "${Error} tinyPortMapper 最新版本获取失败，请手动获取最新版本号[ https://github.com/wangyu-/tinyPortMapper/releases ]"
		read -e -p "请输入版本号 [ 格式是日期 , 如 20180224.0 ] :" tinymapper_new_ver
		[[ -z "${tinymapper_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 检测到 tinyPortMapper 最新版本为 [ ${tinymapper_new_ver} ]"
	fi
}
Download_tinyPortMapper(){
	cd ${Folder}
	wget -N --no-check-certificate "https://github.com/wangyu-/tinyPortMapper/releases/download/${tinymapper_new_ver}/tinymapper_binaries.tar.gz"
	[[ ! -e "tinymapper_binaries.tar.gz" ]] && echo -e "${Error} tinyPortMapper 压缩包下载失败 !" && exit 1
	tar -xzf tinymapper_binaries.tar.gz
	if [[ ${bit} == "x86_64" ]]; then
		[[ ! -e "tinymapper_amd64" ]] && echo -e "${Error} tinyPortMapper 解压失败 !" && exit 1
		mv tinymapper_amd64 tinymapper
	else
		[[ ! -e "tinymapper_x86" ]] && echo -e "${Error} tinyPortMapper 解压失败 !" && exit 1
		mv tinymapper_x86 tinymapper
	fi
	[[ ! -e "tinymapper" ]] && echo -e "${Error} tinyPortMapper 重命名失败 !" && exit 1
	chmod +x tinymapper
	rm -rf version.txt
	rm -rf tinymapper_*
	rm -rf tinymapper_binaries.tar.gz
}
Install_tinyPortMapper(){
	[[ -e ${File} ]] && echo -e "${Error} 已经安装 tinyPortMapper , 请检查 !" && exit 1
	mkdir ${Folder}
	check_new_ver
	Download_tinyPortMapper
	Set_iptables
	echo -e "${Info} tinyPortMapper 安装完成！"
}
Uninstall_tinyPortMapper(){
	check_tinyPortMapper
	echo "确定要 卸载 tinyPortMapper？[y/N]" && echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		Uninstall_forwarding "Uninstall"
		rm -rf ${Folder}
		echo && echo " tinyPortMapper 卸载完成 !" && echo
	else
		echo && echo " 卸载已取消..." && echo
	fi
}
Uninstall_forwarding(){
	Uninstall_forwarding_Type=$1
	check_tinyPortMapper
	tinymapper_Total=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh" | wc -l)
	if [[ ${tinymapper_Total} != "0" ]]; then
		for((integer = 1; integer <= ${tinymapper_Total}; integer++))
		do
			Uninstall_all=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh")
			Uninstall_pid=$(echo -e "${Uninstall_all}"| sed -n "1p"| awk '{print $2}')
			Uninstall_listen=$(echo -e "${Uninstall_all}"| sed -n "1p"| awk '{print $10}'| awk -F ':' '{print $NF}')
			Uninstall_type_tcp=$(echo -e "${Uninstall_all}"| sed -n "1p"| awk '{print $13}')
			if [[ ${Uninstall_type_tcp} == "-t" ]]; then
			Uninstall_type_udp=$(echo -e "${Uninstall_all}"| sed -n "1p"| awk '{print $14}')
			if [[ ${Uninstall_type_udp} == "-u" ]]; then
				Uninstall_type="all"
			else
				Uninstall_type="tcp"
			fi
			else
				Uninstall_type="udp"
			fi
			kill -9 "${Uninstall_pid}"
			Del_iptables "${Uninstall_type}"
			sleep 1s
		done
	fi
	if [[ ${Uninstall_forwarding_Type} != "Uninstall" ]]; then
		tinymapper_Total=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh" | wc -l)
		if [[ ${tinymapper_Total} == "0" ]]; then
			echo -e "${Info} tinyPortMapper 所有端口转发已清空！"
		else
			echo -e "${Error} tinyPortMapper 所有端口转发清空失败！"
		fi
	fi
}
Add_forwarding(){
	check_tinyPortMapper
	Set_local_Port
	Set_Mapper_Port
	Set_Mapper_IP
	Set_Mapper_Type
	Mapper_Type_1=${Mapper_Type}
	[[ ${Mapper_Type_1} == "ALL" ]] && Mapper_Type_1="TCP+UDP"
	echo -e "\n——————————————————————————————
    请检查 tinyPortMapper 配置是否有误 !\n
	本地监听端口\t : ${Red_background_prefix} ${local_Port} ${Font_color_suffix}
	远程转发 IP\t : ${Red_background_prefix} ${Mapper_IP} ${Font_color_suffix}
	远程转发端口\t : ${Red_background_prefix} ${Mapper_Port} ${Font_color_suffix}
	转发类型\t : ${Red_background_prefix} ${Mapper_Type_1} ${Font_color_suffix}
——————————————————————————————\n"
	read -e -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	Start_tinyPortMapper
	Get_IP
	clear
	echo -e "\n——————————————————————————————
	tinyPortMapper 已启动 !\n
	本地监听 IP\t : ${Red_background_prefix} ${ip} ${Font_color_suffix}
	本地监听端口\t : ${Red_background_prefix} ${local_Port} ${Font_color_suffix}\n
	远程转发 IP\t : ${Red_background_prefix} ${Mapper_IP} ${Font_color_suffix}
	远程转发端口\t : ${Red_background_prefix} ${Mapper_Port} ${Font_color_suffix}
	转发类型\t : ${Red_background_prefix} ${Mapper_Type_1} ${Font_color_suffix}
——————————————————————————————\n"
}
Set_local_Port(){
	while true
	do
		echo -e "请输入 tinyPortMapper 的 本地监听端口 [1-65535]"
		read -e -p "(默认回车取消):" local_Port
		[[ -z "${local_Port}" ]] && echo "已取消..." && exit 1
		echo $((${local_Port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${local_Port} -ge 1 ]] && [[ ${local_Port} -le 65535 ]]; then
				echo
				echo "——————————————————————————————"
				echo -e "	本地监听端口 : ${Red_background_prefix} ${local_Port} ${Font_color_suffix}"
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
}
Set_Mapper_Port(){
	while true
	do
		echo -e "请输入 tinyPortMapper 远程被转发 端口 [1-65535](就是被中转服务器的端口)"
		read -e -p "(默认同本地监听端口: ${local_Port}):" Mapper_Port
		[[ -z "${Mapper_Port}" ]] && Mapper_Port=${local_Port}
		echo $((${Mapper_Port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${Mapper_Port} -ge 1 ]] && [[ ${Mapper_Port} -le 65535 ]]; then
				echo
				echo "——————————————————————————————"
				echo -e "	远程转发端口 : ${Red_background_prefix} ${Mapper_Port} ${Font_color_suffix}"
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
}
Set_Mapper_IP(){
	echo -e "请输入 tinyPortMapper 远程被转发 IP(就是被中转服务器的外网IP)"
	read -e -p "(默认回车取消):" Mapper_IP
	[[ -z "${Mapper_IP}" ]] && echo "已取消..." && exit 1
	echo
	echo "——————————————————————————————"
	echo -e "	远程转发 IP : ${Red_background_prefix} ${Mapper_IP} ${Font_color_suffix}"
	echo "——————————————————————————————"
	echo
}
Set_Mapper_Type(){
	echo -e "请输入数字 来选择 tinyPortMapper 转发类型:"
	echo -e "	1. TCP\n	2. UDP\n	3. TCP+UDP(ALL)\n"
	read -e -p "(默认: TCP+UDP):" Mapper_Type_num
	[[ -z "${Mapper_Type_num}" ]] && Mapper_Type_num="3"
	if [[ ${Mapper_Type_num} = "1" ]]; then
		Mapper_Type="TCP"
	elif [[ ${Mapper_Type_num} = "2" ]]; then
		Mapper_Type="UDP"
	elif [[ ${Mapper_Type_num} = "3" ]]; then
		Mapper_Type="ALL"
	else
		Mapper_Type="ALL"
	fi
}
Start_tinyPortMapper(){
	cd ${Folder}
	if [[ ${Mapper_Type} = "TCP" ]]; then
		Run_tinyPortMapper "-t"
		sleep 2s
		PID=$(ps -ef | grep "./tinymapper -l 0.0.0.0:${local_Port}" | grep -v grep | awk '{print $2}')
		[[ -z ${PID} ]] && echo -e "${Error} tinyPortMapper TCP 启动失败 !" && exit 1
		Add_iptables "tcp"
	elif [[ ${Mapper_Type} = "UDP" ]]; then
		Run_tinyPortMapper "-u"
		sleep 2s
		PID=$(ps -ef | grep "./tinymapper -l 0.0.0.0:${local_Port}" | grep -v grep | awk '{print $2}')
		[[ -z ${PID} ]] && echo -e "${Error} tinyPortMapper UDP 启动失败 !" && exit 1
		Add_iptables "udp"
	elif [[ ${Mapper_Type} = "ALL" ]]; then
		Run_tinyPortMapper "-t -u"
		sleep 2s
		PID=$(ps -ef | grep "./tinymapper -l 0.0.0.0:${local_Port}" | grep -v grep | awk '{print $2}')
		[[ -z ${PID} ]] && echo -e "${Error} tinyPortMapper TCP+UDP 启动失败 !" && exit 1
		Add_iptables "all"
	fi
	Save_iptables
}
Run_tinyPortMapper(){
	nohup ./tinymapper -l 0.0.0.0:${local_Port} -r ${Mapper_IP}:${Mapper_Port} $1 > ${LOG_File} 2>&1 &
}
View_forwarding(){
	check_tinyPortMapper
	tinymapper_Total=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh" | wc -l)
	if [[ ${tinymapper_Total} = "0" ]]; then
		echo -e "${Error} 没有发现 tinyPortMapper 进程运行，请检查 !" && exit 1
	fi
	tinymapper_list_all=""
	for((integer = 1; integer <= ${tinymapper_Total}; integer++))
	do
		tinymapper_all=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh")
		tinymapper_pid=$(echo -e "${tinymapper_all}"| sed -n "${integer}p"| awk '{print $2}')
		tinymapper_listen=$(echo -e "${tinymapper_all}"| sed -n "${integer}p"| awk '{print $10}'| awk -F ':' '{print $NF}')
		tinymapper_fork=$(echo -e "${tinymapper_all}"| sed -n "${integer}p"| awk '{print $12}')
		tinymapper_type_tcp=$(echo -e "${tinymapper_all}"| sed -n "${integer}p"| awk '{print $13}')
		if [[ ${tinymapper_type_tcp} == "-t" ]]; then
		tinymapper_type_udp=$(echo -e "${tinymapper_all}"| sed -n "${integer}p"| awk '{print $14}')
		if [[ ${tinymapper_type_udp} == "-u" ]]; then
			tinymapper_type="TCP+UDP"
		else
			tinymapper_type="TCP"
		fi
		else
			tinymapper_type="UDP"
		fi
		tinymapper_list_all=${tinymapper_list_all}"进程PID: ${Red_font_prefix}"${tinymapper_pid}"${Font_color_suffix} 类型: ${Red_font_prefix}"${tinymapper_type}"${Font_color_suffix} 监听端口: ${Green_font_prefix}"${tinymapper_listen}"${Font_color_suffix} 转发IP和端口: ${Green_font_prefix}"${tinymapper_fork}"${Font_color_suffix}\n"
	done
	echo
	echo -e "当前有${Green_background_prefix}" ${tinymapper_Total} "${Font_color_suffix}个 tinyPortMapper 端口转发进程。"
	echo -e "${tinymapper_list_all}"
}
Del_forwarding(){
	check_tinyPortMapper
	PID=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh" | awk '{print $2}')
	[[ -z $PID ]] && echo -e "${Error} 没有发现 tinyPortMapper 进程运行，请检查 !" && exit 1
	while true
	do
		View_forwarding
		read -e -p "请输入你要终止的 tinyPortMapper 本地监听端口:" Del_forwarding_port
		[[ -z "${Del_forwarding_port}" ]] && echo "已取消..." && exit 0
		Del_port=$(echo -e "${tinymapper_list_all}"|grep ${Del_forwarding_port})
		if [[ ! -z ${Del_port} ]]; then
			port=${Del_forwarding_port}
			Del_all=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh")
			pid=$(echo -e "${Del_all}"| grep "./tinymapper -l 0.0.0.0:${Del_forwarding_port}"| awk '{print $2}')
			Del_type_tcp=$(echo -e "${Del_all}"| grep "./tinymapper -l 0.0.0.0:${Del_forwarding_port}"| awk '{print $13}')
			if [[ ${Del_type_tcp} == "-t" ]]; then
				Del_type_udp=$(echo -e "${Del_all}"| grep "./tinymapper -l 0.0.0.0:${Del_forwarding_port}"| awk '{print $14}')
				if [[ ${Del_type_udp} == "-u" ]]; then
					Del_type="all"
				else
					Del_type="tcp"
				fi
			else
				Del_type="udp"
			fi
			kill -9 ${pid}
			sleep 2s
			pid=$(ps -ef | grep tinymapper | grep -v grep | grep -v "tinymapper.sh"| grep "./tinymapper -l 0.0.0.0:${Del_forwarding_port}"| awk '{print $2}')
			if [[ -z ${pid} ]]; then
				echo -e "${Info} tinyPortMapper [${Del_forwarding_port}] 终止成功！"
				Del_iptables "${Del_type}"
			else
				echo -e "${Error} tinyPortMapper [${Del_forwarding_port}] 终止失败！" && exit 1
			fi
			break
		else
			echo -e "${Error} 请输入正确的端口 !"
		fi
	done
}
# 查看日志
View_Log(){
	[[ ! -e ${LOG_File} ]] && echo -e "${Error} tinyPortMapper 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${LOG_File}${Font_color_suffix} 命令。" && echo
	tail -f ${LOG_File}
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/tinymapper.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/tinymapper.sh" && chmod +x tinymapper.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
[[ ${release} != "centos" ]] && [[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
echo && echo -e " tinyPortMapper 端口转发一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/wlzy-36 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 tinyPortMapper
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 tinyPortMapper
 ${Green_font_prefix}3.${Font_color_suffix} 清空 tinyPortMapper 端口转发
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 查看 tinyPortMapper 端口转发
 ${Green_font_prefix}5.${Font_color_suffix} 添加 tinyPortMapper 端口转发
 ${Green_font_prefix}6.${Font_color_suffix} 删除 tinyPortMapper 端口转发
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 查看 tinyPortMapper 输出日志" && echo
read -e -p " 请输入数字 [0-7]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_tinyPortMapper
	;;
	2)
	Uninstall_tinyPortMapper
	;;
	3)
	Uninstall_forwarding
	;;
	4)
	View_forwarding
	;;
	5)
	Add_forwarding
	;;
	6)
	Del_forwarding
	;;
	7)
	View_Log
	;;
	*)
	echo "请输入正确数字 [0-7]"
	;;
esac