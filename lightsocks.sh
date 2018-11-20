#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Lightsocks
#	Version: 1.0.1
#	Author: Toyo
#	Blog: https://doub.io/lightsocks-jc1/
#=================================================

sh_ver="1.0.1"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/usr/local/lightsocks"
lightsocks_file="/usr/local/lightsocks/lightsocks"
lightsocks_conf=$(echo ${HOME})"/.lightsocks.json"
lightsocks_log="/usr/local/lightsocks/lightsocks.log"
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
	[[ ! -e ${lightsocks_file} ]] && echo -e "${Error} Lightsocks 没有安装，请检查 !" && exit 1
}
check_crontab_installed_status(){
	if [[ ! -e ${Crontab_file} ]]; then
		echo -e "${Error} Crontab 没有安装，开始安装..." && exit 1
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
	PID=`ps -ef| grep "lightsocks"| grep -v "grep" | grep -v "lightsocks.sh"| grep -v "init.d" |grep -v "service" |awk '{print $2}'`
}
check_new_ver(){
	lightsocks_new_ver=$(wget --no-check-certificate -qO- https://github.com/gwuhaolin/lightsocks/releases/latest | grep "<title>" | sed -r 's/.*Release (.+) · gwuhaolin.*/\1/')
	if [[ -z ${lightsocks_new_ver} ]]; then
		echo -e "${Error} Lightsocks 最新版本获取失败，请手动获取最新版本号[ https://github.com/gwuhaolin/lightsocks/releases/latest ]"
		read -e -p "请输入版本号 [ 格式是日期 , 如 1.0.6 ] :" lightsocks_new_ver
		[[ -z "${lightsocks_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 检测到 Lightsocks 最新版本为 [ ${lightsocks_new_ver} ]"
	fi
}
check_ver_comparison(){
	check_pid
	[[ ! -z $PID ]] && kill -9 ${PID}
	rm -rf ${lightsocks_file}
	Download_lightsocks
	Start_lightsocks
}
Download_lightsocks(){
	cd ${file}
	if [ ${bit} == "x86_64" ]; then
		wget --no-check-certificate -N "https://github.com/gwuhaolin/lightsocks/releases/download/${lightsocks_new_ver}/lightsocks_${lightsocks_new_ver}_linux_amd64.tar.gz"
		mv "lightsocks_${lightsocks_new_ver}_linux_amd64.tar.gz" "lightsocks_linux.tar.gz"
	else
		wget --no-check-certificate -N "https://github.com/gwuhaolin/lightsocks/releases/download/${lightsocks_new_ver}/lightsocks_${lightsocks_new_ver}_linux_386.tar.gz"
		mv "lightsocks_${lightsocks_new_ver}_linux_386.tar.gz" "lightsocks_linux.tar.gz"
	fi
	[[ ! -s "lightsocks_linux.tar.gz" ]] && echo -e "${Error} Lightsocks 压缩包下载失败 !" && rm -rf "${file}" && exit 1
	tar -xzf "lightsocks_linux.tar.gz"
	rm -rf lightsocks_linux.tar.gz
	[[ ! -e "lightsocks-server" ]] && echo -e "${Error} Lightsocks 压缩包解压失败 !" && rm -rf "${file}" && exit 1
	mv lightsocks-server lightsocks
	chmod +x lightsocks
	rm -rf lightsocks-local
	rm -rf LICENSE
	rm -rf readme.md
}
Service_lightsocks(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/lightsocks_centos" -O /etc/init.d/lightsocks; then
			echo -e "${Error} Lightsocks服务 管理脚本下载失败 !" && rm -rf "${file}" && exit 1
		fi
		chmod +x "/etc/init.d/lightsocks"
		chkconfig --add lightsocks
		chkconfig lightsocks on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/lightsocks_debian" -O /etc/init.d/lightsocks; then
			echo -e "${Error} Lightsocks服务 管理脚本下载失败 !" && rm -rf "${file}" && exit 1
		fi
		chmod +x "/etc/init.d/lightsocks"
		update-rc.d -f lightsocks defaults
	fi
	echo -e "${Info} Lightsocks服务 管理脚本下载完成 !"
}
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		Centos_yum
	else
		Debian_apt
	fi
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	mkdir ${file}
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
Generate_the_port(){
	min=$1
	max=$(($2-$min+1))
	num=$(date +%s%N)
	echo $(($num%$max+$min))
}
Write_config(){
	cat > ${lightsocks_conf}<<-EOF
{
	"listen": ":${ls_port}",
	"remote": ""
}
EOF
}
Read_config(){
	[[ ! -e ${lightsocks_conf} ]] && echo -e "${Error} Lightsocks 配置文件不存在 !" && exit 1
	user_all=$(cat ${lightsocks_conf}|sed "1d;$d")
	[[ -z ${user_all} ]] && echo -e "${Error} Lightsocks 配置文件中用户配置为空 !" && exit 1
	port=$(echo "${user_all}"|grep "listen"|awk -F ': ' '{print $NF}'|sed 's/\"//g;s/://g;s/,//g')
	password=$(echo "${user_all}"|grep "password"|awk -F ': ' '{print $NF}'|sed 's/\"//g')
}
Set_port(){
	while true
		do
		echo -e "请输入 Lightsocks 端口 [1-65535]（端口不能重复，避免冲突）"
		read -e -p "(默认: 随机端口):" ls_port
		[[ -z "${ls_port}" ]] && ls_port=$(Generate_the_port 443 65500)
		echo $((${ls_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${ls_port} -ge 1 ]] && [[ ${ls_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	端口 : ${Red_background_prefix} ${ls_port} ${Font_color_suffix}"
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
Set_lightsocks(){
	check_installed_status
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  修改 端口配置
 ${Green_font_prefix}2.${Font_color_suffix}  修改 密码配置
————————————————
 ${Green_font_prefix}3.${Font_color_suffix}  监控 运行状态
 
 ${Tip} 因为 Lightsocks 限制，所以密码只能自动生成 !" && echo
	read -e -p "(默认: 取消):" ls_modify
	[[ -z "${ls_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${ls_modify} == "1" ]]; then
		Modify_user "port"
	elif [[ ${ls_modify} == "2" ]]; then
		Modify_user "password"
	elif [[ ${ls_modify} == "3" ]]; then
		Set_crontab_monitor_lightsocks
	else
		echo -e "${Error} 请输入正确的数字(1-2)" && exit 1
	fi
}
Modify_user(){
	Read_config
	Modify_user_type=$1
	if [[ ${Modify_user_type} == "port" ]]; then
		Set_port
		Modify_config_port
		Del_iptables
		Add_iptables
		Save_iptables
	else
		Modify_config_password
	fi
	Restart_lightsocks
}
Modify_config_port(){
	sed -i 's/"listen": ":'"$(echo ${port})"'"/"listen": ":'"$(echo ${ls_port})"'"/g' ${lightsocks_conf}
}
Modify_config_password(){
	Read_config
	password_num=$(cat "${lightsocks_conf}"|grep -n '"password":'|awk -F ':' '{print $1}')
	if [[ ${password_num} -gt 0 ]];then
		sed -i "${password_num}d" ${lightsocks_conf}
		password_num_1=$(echo $((${password_num}-1)))
		sed -i "${password_num_1}s/,//g" ${lightsocks_conf}
	else
		echo -e "${Error} 配置文件修改错误！"
	fi
}
Install_lightsocks(){
	check_root
	[[ -e ${lightsocks_file} ]] && echo -e "${Error} 检测到 Lightsocks 已安装 !" && exit 1
	echo -e "${Info} 开始设置 用户配置..."
	Set_port
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始检测最新版本..."
	check_new_ver
	echo -e "${Info} 开始下载/安装..."
	Download_lightsocks
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_lightsocks
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_lightsocks
}
Start_lightsocks(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Lightsocks 正在运行，请检查 !" && exit 1
	/etc/init.d/lightsocks start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_lightsocks
}
Stop_lightsocks(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Lightsocks 没有运行，请检查 !" && exit 1
	/etc/init.d/lightsocks stop
}
Restart_lightsocks(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/lightsocks stop
	/etc/init.d/lightsocks start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_lightsocks
}
Update_lightsocks(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall_lightsocks(){
	check_installed_status
	echo "确定要卸载 Lightsocks ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		if [[ -e ${lightsocks_conf} ]]; then
			Read_config
			Del_iptables
			Save_iptables
			rm -rf "${lightsocks_conf}"
		fi
		rm -rf "${file}"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del lightsocks
		else
			update-rc.d -f lightsocks remove
		fi
		rm -rf "/etc/init.d/lightsocks"
		echo && echo "Lightsocks 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_lightsocks(){
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
	clear && echo
	echo -e "Lightsocks 用户配置："
		lightsocks_link
		echo -e "————————————————"
		echo -e " 地址\t: ${Green_font_prefix}${ip}${Font_color_suffix}"
		echo -e " 端口\t: ${Green_font_prefix}${port}${Font_color_suffix}"
		echo -e " 密码\t: ${Green_font_prefix}${password}${Font_color_suffix}"
		echo -e "${Lightsocks_link_1}"
	echo
	echo -e "${Tip} Lightsocks链接 仅适用于Windows系统的 Lightsocks Tools客户端[https://doub.io/dbrj-12/]。"
	echo
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n//g;s/=//g;s/+/-/g;s/\//_/g;ta')
	echo -e "${date}"
}
lightsocks_link(){
	Lightsocks_URL_1=$(urlsafe_base64 "${ip}:${port}:${password}")
	Lightsocks_URL="lightsocks://${Lightsocks_URL_1}"
	Lightsocks_QRcode="http://doub.pw/qr/qr.php?text=${Lightsocks_URL}"
	Lightsocks_link_1=" 链接\t: ${Red_font_prefix}${Lightsocks_URL}${Font_color_suffix} \n 二维码 : ${Red_font_prefix}${Lightsocks_QRcode}${Font_color_suffix} \n "
}
View_Log(){
	check_installed_status
	[[ ! -e ${lightsocks_log} ]] && echo -e "${Error} Lightsocks 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志(正常情况下是没有多少日志输出的)" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${lightsocks_log}${Font_color_suffix} 命令。" && echo
	tail -f ${lightsocks_log}
}
# 显示 连接信息
debian_View_user_connection_info(){
	format_1=$1
	Read_config
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'lightsocks' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
	echo -e "链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
	user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'lightsocks' |grep 'tcp6' |grep ":${port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
	if [[ -z ${user_IP_1} ]]; then
		user_IP_total="0"
		echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
	else
		user_IP_total=`echo -e "${user_IP_1}"|wc -l`
		if [[ ${format_1} == "IP_address" ]]; then
			echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
			get_IP_address
			echo
		else
			user_IP=$(echo -e "\n${user_IP_1}")
			echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		fi
	fi
}
centos_View_user_connection_info(){
	format_1=$1
	Read_config
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'lightsocks' |grep 'tcp' | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" |wc -l`
	echo -e "链接IP总数: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
	user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'lightsocks' |grep 'tcp' |grep ":${port} "|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
	if [[ -z ${user_IP_1} ]]; then
		user_IP_total="0"
		echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
	else
		user_IP_total=`echo -e "${user_IP_1}"|wc -l`
		if [[ ${format_1} == "IP_address" ]]; then
			echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
			get_IP_address
			echo
		else
			user_IP=$(echo -e "\n${user_IP_1}")
			echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		fi
	fi
}
View_user_connection_info(){
	check_installed_status
	echo && echo -e "请选择要显示的格式：
 ${Green_font_prefix}1.${Font_color_suffix} 显示 IP 格式
 ${Green_font_prefix}2.${Font_color_suffix} 显示 IP+IP归属地 格式" && echo
	read -e -p "(默认: 1):" lightsocks_connection_info
	[[ -z "${lightsocks_connection_info}" ]] && lightsocks_connection_info="1"
	if [[ "${lightsocks_connection_info}" == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ "${lightsocks_connection_info}" == "2" ]]; then
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
Set_crontab_monitor_lightsocks(){
	check_crontab_installed_status
	crontab_monitor_lightsocks_status=$(crontab -l|grep "lightsocks.sh monitor")
	if [[ -z "${crontab_monitor_lightsocks_status}" ]]; then
		echo && echo -e "当前监控模式: ${Green_font_prefix}未开启${Font_color_suffix}" && echo
		echo -e "确定要开启 ${Green_font_prefix}Lightsocks 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动SSR服务端)[Y/n]"
		read -e -p "(默认: y):" crontab_monitor_lightsocks_status_ny
		[[ -z "${crontab_monitor_lightsocks_status_ny}" ]] && crontab_monitor_lightsocks_status_ny="y"
		if [[ ${crontab_monitor_lightsocks_status_ny} == [Yy] ]]; then
			crontab_monitor_lightsocks_cron_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "当前监控模式: ${Green_font_prefix}已开启${Font_color_suffix}" && echo
		echo -e "确定要关闭 ${Green_font_prefix}Lightsocks 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动SSR服务端)[y/N]"
		read -e -p "(默认: n):" crontab_monitor_lightsocks_status_ny
		[[ -z "${crontab_monitor_lightsocks_status_ny}" ]] && crontab_monitor_lightsocks_status_ny="n"
		if [[ ${crontab_monitor_lightsocks_status_ny} == [Yy] ]]; then
			crontab_monitor_lightsocks_cron_stop
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
crontab_monitor_lightsocks_cron_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/lightsocks.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/lightsocks.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "lightsocks.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Lightsocks 服务端运行状态监控功能 启动失败 !" && exit 1
	else
		echo -e "${Info} Lightsocks 服务端运行状态监控功能 启动成功 !"
	fi
}
crontab_monitor_lightsocks_cron_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/lightsocks.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "lightsocks.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Lightsocks 服务端运行状态监控功能 停止失败 !" && exit 1
	else
		echo -e "${Info} Lightsocks 服务端运行状态监控功能 停止成功 !"
	fi
}
crontab_monitor_lightsocks(){
	check_installed_status
	check_pid
	echo "${PID}"
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] 检测到 Lightsocks服务端 未运行 , 开始启动..." | tee -a ${lightsocks_log}
		/etc/init.d/lightsocks start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Lightsocks服务端 启动失败..." | tee -a ${lightsocks_log}
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Lightsocks服务端 启动成功..." | tee -a ${lightsocks_log}
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Lightsocks服务端 进程运行正常..." | tee -a ${lightsocks_log}
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ls_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ls_port} -j ACCEPT
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
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/lightsocks.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/lightsocks" ]]; then
		rm -rf /etc/init.d/lightsocks
		Service_lightsocks
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/lightsocks.sh" && chmod +x lightsocks.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor_lightsocks
else
	echo && echo -e "  Lightsocks 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/lightsocks-jc1 ----
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 Lightsocks
 ${Green_font_prefix} 2.${Font_color_suffix} 升级 Lightsocks
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 Lightsocks
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 Lightsocks
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 Lightsocks
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 Lightsocks
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 账号配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 账号信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 日志信息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 链接信息
————————————" && echo
	if [[ -e ${lightsocks_file} ]]; then
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
		Install_lightsocks
		;;
		2)
		Update_lightsocks
		;;
		3)
		Uninstall_lightsocks
		;;
		4)
		Start_lightsocks
		;;
		5)
		Stop_lightsocks
		;;
		6)
		Restart_lightsocks
		;;
		7)
		Set_lightsocks
		;;
		8)
		View_lightsocks
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