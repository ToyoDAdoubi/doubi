#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: DAZE
#	Version: 1.0.1
#	Author: Toyo
#	Blog: https://doub.io/daze-jc3/
#=================================================

sh_ver="1.0.1"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
Folder="/usr/local/daze"
File="/usr/local/daze/daze"
CONF="/usr/local/daze/daze.conf"
Now_ver_File="/usr/local/daze/ver.txt"
Log_File="/usr/local/daze/daze.log"
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
	[[ ! -e ${File} ]] && echo -e "${Error} DAZE 没有安装，请检查 !" && exit 1
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
	PID=$(ps -ef| grep "daze"| grep -v grep| grep -v "daze.sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}')
}
check_new_ver(){
	new_ver=$(wget --no-check-certificate -qO- -t1 -T3 https://api.github.com/repos/mohanson/daze/releases| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g')
	if [[ -z ${new_ver} ]]; then
		echo -e "${Error} DAZE 最新版本获取失败，请手动获取最新版本号[ https://github.com/mohanson/daze/releases ]"
		read -e -p "请输入版本号 [ 格式如 2018.10.15 ] :" new_ver
		[[ -z "${new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 检测到 DAZE 最新版本为 [ ${new_ver} ]"
	fi
}
check_ver_comparison(){
	now_ver=$(cat ${Now_ver_File})
	[[ -z ${now_ver} ]] && echo "${new_ver}" > ${Now_ver_File}
	if [[ ${now_ver} != ${new_ver} ]]; then
		echo -e "${Info} 发现 DAZE 已有新版本 [ ${new_ver} ]，当前版本 [ ${now_ver} ]"
		read -e -p "是否更新 ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			cp "${CONF}" "/tmp/daze.conf"
			rm -rf ${Folder}
			mkdir ${Folder}
			Download
			mv "/tmp/daze.conf" "${CONF}"
			Start
		fi
	else
		echo -e "${Info} 当前 DAZE 已是最新版本 [ ${new_ver} ]" && exit 1
	fi
}
Download(){
	cd ${Folder}
	if [[ ${bit} == "x86_64" ]]; then
		bit="amd64"
	elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
		bit="386"
	else
		bit="arm"
	fi
	wget --no-check-certificate -N "https://github.com/mohanson/daze/releases/download/${new_ver}/daze_linux_${bit}"
	[[ ! -e "daze_linux_${bit}" ]] && echo -e "${Error} DAZE 下载失败 !" && rm -rf "${Folder}" && exit 1
	mv "daze_linux_${bit}" "daze"
	[[ ! -e "daze" ]] && echo -e "${Error} DAZE 重命名失败 !" && rm -rf "${Folder}" && exit 1
	chmod +x daze
	echo "${new_ver}" > ${Now_ver_File}
}
Service(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/daze_centos -O /etc/init.d/daze; then
			echo -e "${Error} DAZE 服务管理脚本下载失败 !" && rm -rf "${Folder}" && exit 1
		fi
		chmod +x /etc/init.d/daze
		chkconfig --add daze
		chkconfig daze on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/daze_debian -O /etc/init.d/daze; then
			echo -e "${Error} DAZE 服务管理脚本下载失败 !" && rm -rf "${Folder}" && exit 1
		fi
		chmod +x /etc/init.d/daze
		update-rc.d -f daze defaults
	fi
	echo -e "${Info} DAZE 服务管理脚本下载完成 !"
}
Installation_dependency(){
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	mkdir ${Folder}
}
Write_config(){
	cat > ${CONF}<<-EOF
port=${new_port}
password=${new_password}
method=${new_method}
obfs_url=${new_obfs_url}
dns=${new_dns}
EOF
}
Read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} DAZE 配置文件不存在 !" && exit 1
	port=$(cat ${CONF}|grep "port"|awk -F "=" '{print $NF}')
	password=$(cat ${CONF}|grep "password"|awk -F "=" '{print $NF}')
	method=$(cat ${CONF}|grep "method"|awk -F "=" '{print $NF}')
	obfs_url=$(cat ${CONF}|grep "obfs_url"|awk -F "=" '{print $NF}')
	dns=$(cat ${CONF}|grep "dns"|awk -F "=" '{print $NF}')
}
Set_port(){
	while true
		do
		echo -e "请输入 DAZE 监听端口 [1-65535]（如果要混淆伪装，建议使用：80 8080 8880）"
		read -e -p "(默认: 8880):" new_port
		[[ -z "${new_port}" ]] && new_port="8880"
		echo $((${new_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${new_port} -ge 1 ]] && [[ ${new_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	端口 : ${Red_background_prefix} ${new_port} ${Font_color_suffix}"
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
Set_password(){
	echo "请输入 DAZE 密码"
	read -e -p "(默认: doub.io):" new_password
	[[ -z "${new_password}" ]] && new_password="doub.io"
	echo && echo "========================"
	echo -e "	密码 : ${Red_background_prefix} ${new_password} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_method(){
	echo -e "请选择 DAZE 加密方式(或者说混淆)
	
 ${Green_font_prefix}1.${Font_color_suffix} ashe (仅加密无混淆)
 ${Green_font_prefix}2.${Font_color_suffix} asheshadow (加密+HTTP混淆，注意后面务必填写混淆伪装的网站)
 ${Tip} 如果使用 asheshadow，那么建议搭配 80 8080 等端口，如果你有域名，请域名A记录指向当前服务器IP，DAZE 客户端处服务器地址填写你的域名，即可混淆伪装为 http://域名:端口/" && echo
	read -e -p "(默认: 1. ashe):" new_method
	[[ -z "${new_method}" ]] && new_method="3"
	if [[ ${new_method} == "1" ]]; then
		new_method="ashe"
	elif [[ ${new_method} == "2" ]]; then
		new_method="asheshadow"
	else
		new_method="ashe"
	fi
	echo && echo "========================"
	echo -e "	加密 : ${Red_background_prefix} ${new_method^^} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_obfs_url(){
	echo "请输入 DAZE 要混淆伪装的网站，如果加密方式为 asheshadow，请务必填写(反向代理，只支持 HTTP:// 网站)
建议混淆伪装网站具备以下特点：有 http:// 地址，且不强制重定向为 https://，该网站大流量传输属于正常情况，推荐使用 CentOS Debian Ubuntu 等系统的内核仓库地址。"
	read -e -p "(默认不伪装):" new_obfs_url
	if [[ ! -z ${new_obfs_url} ]]; then
		echo && echo "========================"
		echo -e "	伪装 : ${Red_background_prefix} ${new_obfs_url} ${Font_color_suffix}"
		echo "========================" && echo
	fi
}
Set_dns(){
	echo "请输入 DAZE 要来解析域名的 DNS (目前只支持 53 端口的DNS，例如：8.8.8.8:53)"
	read -e -p "(默认: 8.8.8.8:53):" new_dns
	[[ -z "${new_dns}" ]] && new_dns="8.8.8.8:53"
	echo && echo "========================"
	echo -e "	DNS : ${Red_background_prefix} ${new_dns} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_conf(){
	Set_port
	Set_password
	Set_method
	Set_obfs_url
	Set_dns
}
Modify_restart(){
	echo -e "是否要立刻重启? (Y/n)"
	read -e -p "(默认: Y):" Modify_restart_yn
	[[ -z ${Modify_restart_yn} ]] && Modify_restart_yn="Y"
	if [[ ${Modify_restart_yn} == [Yy] ]]; then
		Restart
	else
		echo -e "已取消..."
	fi
}
Modify_port(){
	Read_config
	Set_port
	new_password="${password}"
	new_obfs_url="${obfs_url}"
	new_method="${method}"
	new_dns="${dns}"
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Modify_restart
}
Modify_password(){
	Read_config
	Set_password
	new_port="${port}"
	new_obfs_url="${obfs_url}"
	new_method="${method}"
	new_dns="${dns}"
	Write_config
	Modify_restart
}
Modify_obfs_url(){
	Read_config
	Set_obfs_url
	new_port="${port}"
	new_password="${password}"
	new_method="${method}"
	new_dns="${dns}"
	Write_config
	Modify_restart
}
Modify_method(){
	Read_config
	Set_method
	new_port="${port}"
	new_password="${password}"
	new_obfs_url="${obfs_url}"
	new_dns="${dns}"
	Write_config
	Modify_restart
}
Modify_dns(){
	Read_config
	Set_method
	new_port="${port}"
	new_password="${password}"
	new_method="${method}"
	new_obfs_url="${obfs_url}"
	Write_config
	Modify_restart
}
Modify_all(){
	Read_config
	Set_conf
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Modify_restart
}
Set(){
	check_installed_status
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  修改 端口配置
 ${Green_font_prefix}2.${Font_color_suffix}  修改 密码配置
 ${Green_font_prefix}3.${Font_color_suffix}  修改 加密方式(以及混淆)
 ${Green_font_prefix}4.${Font_color_suffix}  修改 伪装配置(反向代理)
 ${Green_font_prefix}5.${Font_color_suffix}  修改 DNS 配置
 ${Green_font_prefix}6.${Font_color_suffix}  修改 全部配置
————————————————
 ${Green_font_prefix}7.${Font_color_suffix}  监控 运行状态
 
 ${Tip} 用户的端口是不能重复的，密码可以重复 !" && echo
	read -e -p "(默认: 取消):" gf_modify
	[[ -z "${gf_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${gf_modify} == "1" ]]; then
		Modify_port
	elif [[ ${gf_modify} == "2" ]]; then
		Modify_password
	elif [[ ${gf_modify} == "3" ]]; then
		Modify_method
	elif [[ ${gf_modify} == "4" ]]; then
		Modify_obfs_url
	elif [[ ${gf_modify} == "5" ]]; then
		Modify_dns
	elif [[ ${gf_modify} == "6" ]]; then
		Modify_all
	elif [[ ${gf_modify} == "7" ]]; then
		Set_crontab_monitor
	else
		echo -e "${Error} 请输入正确的数字(1-6)" && exit 1
	fi
}
Install(){
	check_root
	[[ -e ${File} ]] && echo -e "${Error} 检测到 DAZE 已安装 !" && exit 1
	echo -e "${Info} 开始设置 用户配置..."
	Set_conf
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始检测最新版本..."
	check_new_ver
	echo -e "${Info} 开始下载/安装..."
	Download
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start
}
Start(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} DAZE 正在运行，请检查 !" && exit 1
	/etc/init.d/daze start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_daze
}
Stop(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} DAZE 没有运行，请检查 !" && exit 1
	/etc/init.d/daze stop
}
Restart(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/daze stop
	/etc/init.d/daze start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_daze
}
Update(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall(){
	check_installed_status
	echo -e "确定要卸载 DAZE ? (y/N)"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		Save_iptables
		rm -rf ${Folder}
		if [[ ${release} = "centos" ]]; then
			chkconfig --del daze
		else
			update-rc.d -f daze remove
		fi
		rm -rf /etc/init.d/daze
		echo && echo "DAZE 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_daze(){
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
	[[ -z ${obfs_url} ]] && obfs_url="无"
	link_qr
	clear && echo "————————————————" && echo
	echo -e " DAZE 账号信息 :" && echo
	echo -e " 地址\t: ${Green_font_prefix}${ip}${Font_color_suffix}"
	echo -e " 端口\t: ${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 密码\t: ${Green_font_prefix}${password}${Font_color_suffix}"
	echo -e " 加密\t: ${Green_font_prefix}${method}${Font_color_suffix}"
	echo -e " 伪装\t: ${Green_font_prefix}${obfs_url}${Font_color_suffix}"
	echo -e " DNS \t: ${Green_font_prefix}${dns}${Font_color_suffix}"
	echo -e "${link}"
	echo -e "${Tip} 链接仅适用于Windows系统的 DAZE Tools 客户端（https://doub.io/dbrj-17/）。"
	echo && echo "————————————————"
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n//g;ta'|sed 's/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
link_qr(){
	PWDbase64=$(urlsafe_base64 "${password}")
	base64=$(urlsafe_base64 "${ip}:${port}@${PWDbase64}:${method}")
	url="daze://${base64}"
	QRcode="http://doub.pw/qr/qr.php?text=${url}"
	link=" 链接\t: ${Red_font_prefix}${url}${Font_color_suffix} \n 二维码 : ${Red_font_prefix}${QRcode}${Font_color_suffix} \n "
}
View_Log(){
	check_installed_status
	[[ ! -e ${Log_File} ]] && echo -e "${Error} DAZE 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志"
	echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${Log_File}${Font_color_suffix} 命令。"
	echo -e "如果需要清理日志，请用 ${Red_font_prefix}echo \"\" > ${Log_File}${Font_color_suffix} 命令。" && echo
	tail -f ${Log_File}
}
# 显示 连接信息
debian_View_user_connection_info(){
	format_1=$1
	Read_config
	user_port=${port}
	user_IP_1=$(netstat -anp |grep 'ESTABLISHED' |grep 'daze' |grep 'tcp6' |grep ":${user_port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
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
}
centos_View_user_connection_info(){
	format_1=$1
	Read_config
	user_port=${port}
	user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'daze' |grep 'tcp' |grep ":${user_port} "|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
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
}
View_user_connection_info(){
	check_installed_status
	echo && echo -e "请选择要显示的格式：
 ${Green_font_prefix}1.${Font_color_suffix} 显示 IP 格式
 ${Green_font_prefix}2.${Font_color_suffix} 显示 IP+IP归属地 格式" && echo
	read -e -p "(默认: 1):" daze_connection_info
	[[ -z "${daze_connection_info}" ]] && daze_connection_info="1"
	if [[ "${daze_connection_info}" == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ "${daze_connection_info}" == "2" ]]; then
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
Set_crontab_monitor(){
	check_crontab_installed_status
	crontab_monitor_status=$(crontab -l|grep "daze.sh monitor")
	if [[ -z "${crontab_monitor_status}" ]]; then
		echo && echo -e "当前监控模式: ${Green_font_prefix}未开启${Font_color_suffix}" && echo
		echo -e "确定要开启 ${Green_font_prefix}DAZE 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 DAZE 服务端)[Y/n]"
		read -e -p "(默认: y):" crontab_monitor_status_ny
		[[ -z "${crontab_monitor_status_ny}" ]] && crontab_monitor_status_ny="y"
		if [[ ${crontab_monitor_status_ny} == [Yy] ]]; then
			crontab_monitor_cron_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "当前监控模式: ${Green_font_prefix}已开启${Font_color_suffix}" && echo
		echo -e "确定要关闭 ${Green_font_prefix}DAZE 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 DAZE 服务端)[y/N]"
		read -e -p "(默认: n):" crontab_monitor_status_ny
		[[ -z "${crontab_monitor_status_ny}" ]] && crontab_monitor_status_ny="n"
		if [[ ${crontab_monitor_status_ny} == [Yy] ]]; then
			crontab_monitor_cron_stop
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
crontab_monitor_cron_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/daze.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/daze.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "daze.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} DAZE 服务端运行状态监控功能 启动失败 !" && exit 1
	else
		echo -e "${Info} DAZE 服务端运行状态监控功能 启动成功 !"
	fi
}
crontab_monitor_cron_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/daze.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "daze.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} DAZE 服务端运行状态监控功能 停止失败 !" && exit 1
	else
		echo -e "${Info} DAZE 服务端运行状态监控功能 停止成功 !"
	fi
}
crontab_monitor(){
	check_installed_status
	check_pid
	echo "${PID}"
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] 检测到 DAZE 服务端 未运行 , 开始启动..." | tee -a ${Log_File}
		/etc/init.d/daze start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] DAZE 服务端 启动失败..." | tee -a ${Log_File}
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] DAZE 服务端 启动成功..." | tee -a ${Log_File}
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] DAZE 服务端 进程运行正常..." | tee -a ${Log_File}
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${new_port} -j ACCEPT
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
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/daze.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/daze" ]]; then
		rm -rf /etc/init.d/daze
		Service
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/daze.sh" && chmod +x daze.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor
else
echo && echo -e "  DAZE 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/daze-jc3 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 DAZE
 ${Green_font_prefix} 2.${Font_color_suffix} 升级 DAZE
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 DAZE
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 DAZE
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 DAZE
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 DAZE
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 账号配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 账号信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 日志信息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 链接信息
————————————" && echo
if [[ -e ${File} ]]; then
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
	Install
	;;
	2)
	Update
	;;
	3)
	Uninstall
	;;
	4)
	Start
	;;
	5)
	Stop
	;;
	6)
	Restart
	;;
	7)
	Set
	;;
	8)
	View_daze
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