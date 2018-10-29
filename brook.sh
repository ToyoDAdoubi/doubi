#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Brook
#	Version: 1.1.13
#	Author: Toyo
#	Blog: https://doub.io/brook-jc3/
#=================================================

sh_ver="1.1.13"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/usr/local/brook"
brook_file="/usr/local/brook/brook"
brook_conf="/usr/local/brook/brook.conf"
brook_log="/usr/local/brook/brook.log"
Crontab_file="/usr/bin/crontab"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
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
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${brook_file} ]] && echo -e "${Error} Brook 没有安装，请检查 !" && exit 1
}
check_crontab_installed_status(){
	if [[ ! -e ${Crontab_file} ]]; then
		echo -e "${Error} Crontab 没有安装，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install crond -y
		else
			apt-get install cron -y
		fi
		if [[ ! -e ${Crontab_file} ]]; then
			echo -e "${Error} Crontab 安装失败，请检查！" && exit 1
		else
			echo -e "${Info} Crontab 安装成功！"
		fi
	fi
}
check_pid(){
	PID=$(ps -ef| grep "./brook "| grep -v "grep" | grep -v "brook.sh" | grep -v "init.d" |grep -v "service" |awk '{print $2}')
}
check_new_ver(){
	echo -e "请输入要下载安装的 Brook 版本号 ${Green_font_prefix}[ 格式是日期，例如: v20180707 ]${Font_color_suffix}
版本列表请去这里获取：${Green_font_prefix}[ https://github.com/txthinking/brook/releases ]${Font_color_suffix}"
	read -e -p "直接回车即自动获取:" brook_new_ver
	if [[ -z ${brook_new_ver} ]]; then
		brook_new_ver=$(wget -qO- https://api.github.com/repos/txthinking/brook/releases| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g')
		[[ -z ${brook_new_ver} ]] && echo -e "${Error} Brook 最新版本获取失败！" && exit 1
		echo -e "${Info} 检测到 Brook 最新版本为 [ ${brook_new_ver} ]"
	else
		echo -e "${Info} 开始下载 Brook [ ${brook_new_ver} ] 版本！"
	fi
}
check_ver_comparison(){
	brook_now_ver=$(${brook_file} -v|awk '{print $3}')
	[[ -z ${brook_now_ver} ]] && echo -e "${Error} Brook 当前版本获取失败 !" && exit 1
	brook_now_ver="v${brook_now_ver}"
	if [[ "${brook_now_ver}" != "${brook_new_ver}" ]]; then
		echo -e "${Info} 发现 Brook 已有新版本 [ ${brook_new_ver} ]，旧版本 [ ${brook_now_ver} ]"
		read -e -p "是否更新 ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			rm -rf ${brook_file}
			Download_brook
			Start_brook
		fi
	else
		echo -e "${Info} 当前 Brook 已是最新版本 [ ${brook_new_ver} ]" && exit 1
	fi
}
Download_brook(){
	[[ ! -e ${file} ]] && mkdir ${file}
	cd ${file}
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -N "https://github.com/txthinking/brook/releases/download/${brook_new_ver}/brook"
	else
		wget --no-check-certificate -N "https://github.com/txthinking/brook/releases/download/${brook_new_ver}/brook_linux_386"
		mv brook_linux_386 brook
	fi
	[[ ! -e "brook" ]] && echo -e "${Error} Brook 下载失败 !" && rm -rf "${file}" && exit 1
	chmod +x brook
}
Service_brook(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/brook_centos" -O /etc/init.d/brook; then
			echo -e "${Error} Brook服务 管理脚本下载失败 !" && rm -rf "${file}" && exit 1
		fi
		chmod +x "/etc/init.d/brook"
		chkconfig --add brook
		chkconfig brook on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/brook_debian" -O /etc/init.d/brook; then
			echo -e "${Error} Brook服务 管理脚本下载失败 !" && rm -rf "${file}" && exit 1
		fi
		chmod +x "/etc/init.d/brook"
		update-rc.d -f brook defaults
	fi
	echo -e "${Info} Brook服务 管理脚本下载完成 !"
}
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		Centos_yum
	else
		Debian_apt
	fi
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
Centos_yum(){
	cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
	if [[ $? = 0 ]]; then
		yum update
		yum install -y net-tools
	fi
}
Debian_apt(){
	cat /etc/issue |grep 9\..*>/dev/null
	if [[ $? = 0 ]]; then
		apt-get update
		apt-get install -y net-tools
	fi
}
Write_config(){
	cat > ${brook_conf}<<-EOF
${bk_protocol}
${bk_port} ${bk_passwd}
EOF
}
Read_config(){
	[[ ! -e ${brook_conf} ]] && echo -e "${Error} Brook 配置文件不存在 !" && exit 1
	user_all=$(cat ${brook_conf}|sed "1d")
	user_all_num=$(echo "${user_all}"|wc -l)
	[[ -z ${user_all} ]] && echo -e "${Error} Brook 配置文件中用户配置为空 !" && exit 1
	protocol=$(cat ${brook_conf}|sed -n "1p")
}
Set_port_Modify(){
	while true
		do
		echo -e "请选择并输入要修改的 Brook 账号端口 [1-65535]"
		read -e -p "(默认取消):" bk_port_Modify
		[[ -z "${bk_port_Modify}" ]] && echo "取消..." && exit 1
		echo $((${bk_port_Modify}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${bk_port_Modify} -ge 1 ]] && [[ ${bk_port_Modify} -le 65535 ]]; then
				check_port "${bk_port_Modify}"
				if [[ $? == 0 ]]; then
					break
				else
					echo -e "${Error} 该端口不存在 [${bk_port_Modify}] !"
				fi
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
		done
}
Set_port(){
	while true
		do
		echo -e "请输入 Brook 端口 [1-65535]（端口不能重复，避免冲突）"
		read -e -p "(默认: 2333):" bk_port
		[[ -z "${bk_port}" ]] && bk_port="2333"
		echo $((${bk_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${bk_port} -ge 1 ]] && [[ ${bk_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	端口 : ${Red_background_prefix} ${bk_port} ${Font_color_suffix}"
				echo "========================" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
		done
}
Set_passwd(){
	echo "请输入 Brook 密码（因分享链接特性，密码请勿包含 % 符号）"
	read -e -p "(默认: doub.io):" bk_passwd
	[[ -z "${bk_passwd}" ]] && bk_passwd="doub.io"
	echo && echo "========================"
	echo -e "	密码 : ${Red_background_prefix} ${bk_passwd} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_protocol(){
	echo -e "请选择 Brook 协议
 ${Green_font_prefix}1.${Font_color_suffix} Brook（新版协议，即 [servers]）
 ${Green_font_prefix}2.${Font_color_suffix} Brook Stream（旧版协议，即 [streamservers]，不推荐，除非使用新版协议速度慢）" && echo
	read -e -p "(默认: 1. Brook（新版协议）):" bk_protocol
	[[ -z "${bk_protocol}" ]] && bk_protocol="1"
	if [[ ${bk_protocol} == "1" ]]; then
		bk_protocol="servers"
	elif [[ ${bk_protocol} == "2" ]]; then
		bk_protocol="streamservers"
	else
		bk_protocol="servers"
	fi
	echo && echo "========================"
	echo -e "	协议 : ${Green_font_prefix}${bk_protocol}${Font_color_suffix}"
	echo "========================" && echo
}
Set_brook(){
	check_installed_status
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  添加 用户配置
 ${Green_font_prefix}2.${Font_color_suffix}  删除 用户配置
 ${Green_font_prefix}3.${Font_color_suffix}  修改 用户配置
 ${Green_font_prefix}4.${Font_color_suffix}  修改 混淆协议
————————————————
 ${Green_font_prefix}5.${Font_color_suffix}  监控 运行状态
 
 ${Tip} 用户的端口是不能重复的，密码可以重复 !" && echo
	read -e -p "(默认: 取消):" bk_modify
	[[ -z "${bk_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${bk_modify} == "1" ]]; then
		Add_port_user
	elif [[ ${bk_modify} == "2" ]]; then
		Del_port_user
	elif [[ ${bk_modify} == "3" ]]; then
		Modify_port_user
	elif [[ ${bk_modify} == "4" ]]; then
		Modify_protocol
	elif [[ ${bk_modify} == "5" ]]; then
		Set_crontab_monitor_brook
	else
		echo -e "${Error} 请输入正确的数字(1-5)" && exit 1
	fi
}
check_port(){
	check_port_1=$1
	user_all=$(cat ${brook_conf}|sed '1d;/^\s*$/d')
	#[[ -z "${user_all}" ]] && echo -e "${Error} Brook 配置文件中用户配置为空 !" && exit 1
	check_port_statu=$(echo "${user_all}"|awk '{print $1}'|grep -w "${check_port_1}")
	if [[ ! -z "${check_port_statu}" ]]; then
		return 0
	else
		return 1
	fi
}
list_port(){
	port_Type=$1
	user_all=$(cat ${brook_conf}|sed '1d;/^\s*$/d')
	if [[ -z "${user_all}" ]]; then
		if [[ "${port_Type}" != "ADD" ]]; then
			echo -e "${Error} Brook 配置文件中用户配置为空 !" && exit 1
		fi
	fi
	port_all_1=$(echo "${user_all}"|awk '{print $1}')
	echo -e "\n当前所有已使用端口：\n${port_all_1}\n========================\n"
}
Add_port_user(){
	list_port "ADD"
	Set_port
	check_port "${bk_port}"
	[[ $? == 0 ]] && echo -e "${Error} 该端口已存在 [${bk_port}] !" && exit 1
	Set_passwd
	echo "${bk_port} ${bk_passwd}" >> ${brook_conf}
	Add_iptables
	Save_iptables
	Restart_brook
}
Del_port_user(){
	list_port
	Set_port
	check_port "${bk_port}"
	[[ $? == 1 ]] && echo -e "${Error} 该端口不存在 [${bk_port}] !" && exit 1
	sed -i "/^${bk_port} /d" ${brook_conf}
	port=${bk_port}
	Del_iptables
	Save_iptables
	port_num=$(cat ${brook_conf}|sed '1d;/^\s*$/d'|wc -l)
	if [[ ${port_num} == 0 ]]; then
		echo -e "${Error} 已无任何端口 !"
		Stop_brook
	else
		Restart_brook
	fi
}
Modify_port_user(){
	list_port
	Set_port_Modify
	echo -e "\n${Info} 开始输入新端口... \n"
	Set_port
	check_port "${bk_port}"
	if [[ $? == 0 ]]; then
		if [[ "${bk_port_Modify}" != "${bk_port}" ]]; then
		echo -e "${Error} 该端口已存在 [${bk_port}] !" && exit 1
		fi
	fi
	Set_passwd
	sed -i "/^${bk_port_Modify} /d" ${brook_conf}
	echo "${bk_port} ${bk_passwd}" >> ${brook_conf}
	port=${bk_port_Modify}
	Del_iptables
	Add_iptables
	Save_iptables
	Restart_brook
}
Modify_protocol(){
	Set_protocol
	sed -i "1d" ${brook_conf}
	sed -i '1i\'${bk_protocol} ${brook_conf}
	Restart_brook
}
Install_brook(){
	check_root
	[[ -e ${brook_file} ]] && echo -e "${Error} 检测到 Brook 已安装 !" && exit 1
	echo -e "${Info} 开始设置 用户配置..."
	Set_port
	Set_passwd
	Set_protocol
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始检测最新版本..."
	check_new_ver
	echo -e "${Info} 开始下载/安装..."
	Download_brook
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_brook
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_brook
}
Start_brook(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Brook 正在运行，请检查 !" && exit 1
	/etc/init.d/brook start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_brook
}
Stop_brook(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Brook 没有运行，请检查 !" && exit 1
	/etc/init.d/brook stop
}
Restart_brook(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/brook stop
	/etc/init.d/brook start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_brook
}
Update_brook(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall_brook(){
	check_installed_status
	echo "确定要卸载 Brook ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		if [[ -e ${brook_conf} ]]; then
			user_all=$(cat ${brook_conf}|sed "1d")
			user_all_num=$(echo "${user_all}"|wc -l)
			if [[ ! -z ${user_all} ]]; then
				for((integer = 1; integer <= ${user_all_num}; integer++))
				do
					user_text=$(echo "${user_all}"|sed -n "${integer}p")
					port=$(echo "${user_text}"|awk '{print $1}')
					Del_iptables
				done
				Save_iptables
			fi
		fi
		if [[ ! -z $(crontab -l | grep "brook.sh monitor") ]]; then
			crontab_monitor_brook_cron_stop
		fi
		rm -rf "${file}"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del brook
		else
			update-rc.d -f brook remove
		fi
		rm -rf "/etc/init.d/brook"
		echo && echo "Brook 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_brook(){
	check_installed_status
	Read_config
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
	if [[ ${protocol} == "servers" ]]; then
		protocol="Brook(新版)"
	elif [[ ${protocol} == "streamservers" ]]; then
		protocol="Brook Stream(旧版)"
	fi
	clear && echo
	echo -e "Brook 用户配置："
	for((integer = 1; integer <= ${user_all_num}; integer++))
		do
			user_text=$(echo "${user_all}"|sed -n "${integer}p")
			port=$(echo "${user_text}"|awk '{print $1}')
			password=$(echo "${user_text}"|awk '{print $2}')
			brook_link
			echo -e "————————————————"
			echo -e " 地址\t: ${Green_font_prefix}${ip}${Font_color_suffix}"
			echo -e " 端口\t: ${Green_font_prefix}${port}${Font_color_suffix}"
			echo -e " 密码\t: ${Green_font_prefix}${password}${Font_color_suffix}"
			echo -e " 协议\t: ${Green_font_prefix}${protocol}${Font_color_suffix}"
			echo -e "${Brook_link_1}"
	done
	echo
	echo -e "${Tip} Brook链接 仅适用于Windows系统的 Brook Tools客户端（https://doub.io/dbrj-7/）。"
	echo
}
brook_link(){
	if [[ "${protocol}" == "Brook(新版)" ]]; then
		Brook_URL_1="default ${ip}:${port} ${password}"
	else
		Brook_URL_1="stream ${ip}:${port} ${password}"
	fi
	#printf $(echo -n "xxx" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')"\n"
	Brook_URL_1=$(echo "${Brook_URL_1}"|sed 's/ /%20/g;s/!/%21/g;s/#/%23/g;s/\$/%24/g;s/&/%26/g;s/'"'"'/%27/g;s/(/%28/g;s/)/%29/g;s/*/%2A/g;s/+/%2B/g;s/,/%2C/g;s/\//%2F/g;s/:/%3A/g;s/;/%3B/g;s/=/%3D/g;s/?/%3F/g;s/@/%40/g;s/\[/%5B/g;s/\]/%5D/g')
	Brook_URL="brook://${Brook_URL_1}"
	Brook_link_1=" Brook 链接 : ${Green_font_prefix}${Brook_URL}${Font_color_suffix}"
}
View_Log(){
	check_installed_status
	[[ ! -e ${brook_log} ]] && echo -e "${Error} Brook 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志(正常情况是没有使用日志记录的)" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${brook_log}${Font_color_suffix} 命令。" && echo
	tail -f ${brook_log}
}
# 显示 连接信息
debian_View_user_connection_info(){
	format_1=$1
	Read_config
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'brook' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
	echo -e "用户总数: ${Green_background_prefix} "${user_all_num}" ${Font_color_suffix} 链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
	
	for((integer = 1; integer <= ${user_all_num}; integer++))
	do
		user_port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'brook' |grep 'tcp6' |grep ":${user_port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
			echo -e "端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				echo -e "端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
				get_IP_address
				echo
			else
				user_IP=$(echo -e "\n${user_IP_1}")
				echo -e "端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
			fi
		fi
		user_IP=""
	done
}
centos_View_user_connection_info(){
	format_1=$1
	Read_config
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'brook' |grep 'tcp' | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
	echo -e "用户总数: ${Green_background_prefix} "${user_all_num}" ${Font_color_suffix} 链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
	
	for((integer = 1; integer <= ${user_all_num}; integer++))
	do
		user_port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'brook' |grep 'tcp' |grep ":${user_port} "|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
			echo -e "端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				echo -e "端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
				get_IP_address
				echo
			else
				user_IP=$(echo -e "\n${user_IP_1}")
				echo -e "端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
			fi
		fi
		user_IP=""
	done
}
View_user_connection_info(){
	check_installed_status
	echo && echo -e "请选择要显示的格式：
 ${Green_font_prefix}1.${Font_color_suffix} 显示 IP 格式
 ${Green_font_prefix}2.${Font_color_suffix} 显示 IP+IP归属地 格式" && echo
	read -e -p "(默认: 1):" brook_connection_info
	[[ -z "${brook_connection_info}" ]] && brook_connection_info="1"
	if [[ "${brook_connection_info}" == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ "${brook_connection_info}" == "2" ]]; then
		echo -e "${Tip} 检测IP归属地(ipip.net)，如果IP较多，可能时间会比较长..."
		View_user_connection_info_1 "IP_address"
	else
		echo -e "${Error} 请输入正确的数字(1-2)" && exit 1
	fi
}
View_user_connection_info_1(){
	format=$1
	if [[ ${release} = "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 0 ]]; then
			debian_View_user_connection_info "$format"
		else
			centos_View_user_connection_info "$format"
		fi
	else
		debian_View_user_connection_info "$format"
	fi
}
get_IP_address(){
	#echo "user_IP_1=${user_IP_1}"
	if [[ ! -z ${user_IP_1} ]]; then
	#echo "user_IP_total=${user_IP_total}"
		for((integer_1 = ${user_IP_total}; integer_1 >= 1; integer_1--))
		do
			IP=$(echo "${user_IP_1}" |sed -n "$integer_1"p)
			#echo "IP=${IP}"
			IP_address=$(wget -qO- -t1 -T2 http://freeapi.ipip.net/${IP}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g')
			#echo "IP_address=${IP_address}"
			#user_IP="${user_IP}\n${IP}(${IP_address})"
			echo -e "${Green_font_prefix}${IP}${Font_color_suffix} (${IP_address})"
			#echo "user_IP=${user_IP}"
			sleep 1s
		done
	fi
}
Set_crontab_monitor_brook(){
	check_crontab_installed_status
	crontab_monitor_brook_status=$(crontab -l|grep "brook.sh monitor")
	if [[ -z "${crontab_monitor_brook_status}" ]]; then
		echo && echo -e "当前监控模式: ${Green_font_prefix}未开启${Font_color_suffix}" && echo
		echo -e "确定要开启 ${Green_font_prefix}Brook 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 Brook 服务端)[Y/n]"
		read -e -p "(默认: y):" crontab_monitor_brook_status_ny
		[[ -z "${crontab_monitor_brook_status_ny}" ]] && crontab_monitor_brook_status_ny="y"
		if [[ ${crontab_monitor_brook_status_ny} == [Yy] ]]; then
			crontab_monitor_brook_cron_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "当前监控模式: ${Green_font_prefix}已开启${Font_color_suffix}" && echo
		echo -e "确定要关闭 ${Green_font_prefix}Brook 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 Brook 服务端)[y/N]"
		read -e -p "(默认: n):" crontab_monitor_brook_status_ny
		[[ -z "${crontab_monitor_brook_status_ny}" ]] && crontab_monitor_brook_status_ny="n"
		if [[ ${crontab_monitor_brook_status_ny} == [Yy] ]]; then
			crontab_monitor_brook_cron_stop
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
crontab_monitor_brook_cron_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/brook.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/brook.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "brook.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Brook 服务端运行状态监控功能 启动失败 !" && exit 1
	else
		echo -e "${Info} Brook 服务端运行状态监控功能 启动成功 !"
	fi
}
crontab_monitor_brook_cron_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/brook.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "brook.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Brook 服务端运行状态监控功能 停止失败 !" && exit 1
	else
		echo -e "${Info} Brook 服务端运行状态监控功能 停止成功 !"
	fi
}
crontab_monitor_brook(){
	check_installed_status
	check_pid
	#echo "${PID}"
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] 检测到 Brook服务端 未运行 , 开始启动..." | tee -a ${brook_log}
		/etc/init.d/brook start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Brook服务端 启动失败..." | tee -a ${brook_log}
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Brook服务端 启动成功..." | tee -a ${brook_log}
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Brook服务端 进程运行正常..." | tee -a ${brook_log}
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${bk_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${bk_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
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
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/brook.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/brook" ]]; then
		rm -rf /etc/init.d/brook
		Service_brook
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/brook.sh" && chmod +x brook.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor_brook
else
	echo && echo -e "  Brook 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/brook-jc3 ----
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 Brook
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 Brook
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 Brook
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 Brook
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 Brook
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 Brook
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 账号配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 账号信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 日志信息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 链接信息
————————————" && echo
	if [[ -e ${brook_file} ]]; then
		check_pid
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
	echo
	read -e -p " 请输入数字 [0-10]:" num
	case "$num" in
		0)
		Update_Shell
		;;
		1)
		Install_brook
		;;
		2)
		Update_brook
		;;
		3)
		Uninstall_brook
		;;
		4)
		Start_brook
		;;
		5)
		Stop_brook
		;;
		6)
		Restart_brook
		;;
		7)
		Set_brook
		;;
		8)
		View_brook
		;;
		9)
		View_Log
		;;
		10)
		View_user_connection_info
		;;
		*)
		echo "请输入正确数字 [0-10]"
		;;
	esac
fi