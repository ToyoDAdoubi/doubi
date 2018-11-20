#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: GoFlyway
#	Version: 1.0.11
#	Author: Toyo
#	Blog: https://doub.io/goflyway-jc2/
#=================================================

sh_ver="1.0.11"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
Folder="/usr/local/goflyway"
File="/usr/local/goflyway/goflyway"
CONF="/usr/local/goflyway/goflyway.conf"
Now_ver_File="/usr/local/goflyway/ver.txt"
Log_File="/usr/local/goflyway/goflyway.log"
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
	[[ ! -e ${File} ]] && echo -e "${Error} GoFlyway 没有安装，请检查 !" && exit 1
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
	PID=$(ps -ef| grep "goflyway"| grep -v grep| grep -v "goflyway.sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}')
}
check_new_ver(){
	new_ver=$(wget --no-check-certificate -qO- -t1 -T3 https://api.github.com/repos/coyove/goflyway/releases| grep "tag_name"|grep -v "caddy"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g')
	if [[ -z ${new_ver} ]]; then
		echo -e "${Error} GoFlyway 最新版本获取失败，请手动获取最新版本号[ https://github.com/coyove/goflyway/releases ]"
		read -e -p "请输入版本号 [ 格式如 1.3.0a ] :" new_ver
		[[ -z "${new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 检测到 GoFlyway 最新版本为 [ ${new_ver} ]"
	fi
}
check_ver_comparison(){
	now_ver=$(cat ${Now_ver_File})
	[[ -z ${now_ver} ]] && echo "${new_ver}" > ${Now_ver_File}
	if [[ ${now_ver} != ${new_ver} ]]; then
		echo -e "${Info} 发现 GoFlyway 已有新版本 [ ${new_ver} ]，当前版本 [ ${now_ver} ]"
		read -e -p "是否更新 ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			cp "${CONF}" "/tmp/goflyway.conf"
			rm -rf ${Folder}
			mkdir ${Folder}
			Download_goflyway
			mv "/tmp/goflyway.conf" "${CONF}"
			Start_goflyway
		fi
	else
		echo -e "${Info} 当前 GoFlyway 已是最新版本 [ ${new_ver} ]" && exit 1
	fi
}
Download_goflyway(){
	cd ${Folder}
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -N "https://github.com/coyove/goflyway/releases/download/${new_ver}/goflyway_linux_amd64.tar.gz"
		mv goflyway_linux_amd64.tar.gz goflyway_linux.tar.gz
	else
		wget --no-check-certificate -N "https://github.com/coyove/goflyway/releases/download/${new_ver}/goflyway_linux_386.tar.gz"
		mv goflyway_linux_386.tar.gz goflyway_linux.tar.gz
	fi
	[[ ! -e "goflyway_linux.tar.gz" ]] && echo -e "${Error} GoFlyway 下载失败 !" && exit 1
	tar -xzf goflyway_linux.tar.gz
	[[ ! -e "goflyway" ]] && echo -e "${Error} GoFlyway 解压失败 !" && rm -f goflyway_linux.tar.gz && exit 1
	rm -f goflyway_linux.tar.gz
	chmod +x goflyway
	./goflyway -gen-ca
	echo "${new_ver}" > ${Now_ver_File}
}
Service_goflyway(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/goflyway_centos -O /etc/init.d/goflyway; then
			echo -e "${Error} GoFlyway 服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/goflyway
		chkconfig --add goflyway
		chkconfig goflyway on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/goflyway_debian -O /etc/init.d/goflyway; then
			echo -e "${Error} GoFlyway 服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/goflyway
		update-rc.d -f goflyway defaults
	fi
	echo -e "${Info} GoFlyway 服务管理脚本下载完成 !"
}
Installation_dependency(){
	mkdir ${Folder}
}
Write_config(){
	cat > ${CONF}<<-EOF
port=${new_port}
passwd=${new_passwd}
protocol=${new_protocol}
proxy_pass=${new_proxy_pass}
EOF
}
Read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} GoFlyway 配置文件不存在 !" && exit 1
	port=$(cat ${CONF}|grep "port"|awk -F "=" '{print $NF}')
	passwd=$(cat ${CONF}|grep "passwd"|awk -F "=" '{print $NF}')
	proxy_pass=$(cat ${CONF}|grep "proxy_pass"|awk -F "=" '{print $NF}')
	protocol=$(cat ${CONF}|grep "protocol"|awk -F "=" '{print $NF}')
	if [[ -z "${protocol}" ]]; then
		protocol="http"
		new_protocol="http"
		new_port="${port}"
		new_passwd="${passwd}"
		new_proxy_pass="${proxy_pass}"
		Write_config
	fi
}
Set_port(){
	while true
		do
		echo -e "请输入 GoFlyway 监听端口 [1-65535]（如果要伪装或者套CDN，那么只能使用端口：80 8080 8880 2052 2082 2086 2095）"
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
Set_passwd(){
	echo "请输入 GoFlyway 密码"
	read -e -p "(默认: doub.io):" new_passwd
	[[ -z "${new_passwd}" ]] && new_passwd="doub.io"
	echo && echo "========================"
	echo -e "	密码 : ${Red_background_prefix} ${new_passwd} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_proxy_pass(){
	echo "请输入 GoFlyway 要伪装的网站(反向代理，只支持 HTTP:// 网站)"
	read -e -p "(默认不伪装):" new_proxy_pass
	if [[ ! -z ${new_proxy_pass} ]]; then
		echo && echo "========================"
		echo -e "	伪装 : ${Red_background_prefix} ${new_proxy_pass} ${Font_color_suffix}"
		echo "========================" && echo
	fi
}
Set_protocol(){
	echo -e "请选择 GoFlyway 传输协议
	
 ${Green_font_prefix}1.${Font_color_suffix} HTTP (默认，要使用 CDN、WebSocket 则必须选择 HTTP 协议)
 ${Green_font_prefix}2.${Font_color_suffix} KCP  (将 TCP 数据转为 KCP，并通过UDP方式传输，可复活被TCP阻断的IP)
 ${Tip} 如果使用 KCP 协议，那么将不能使用 CDN、WebSocket。另外，部分地区对海外的UDP链接会QOS限速，这可能导致 KCP 协议速度不理想。" && echo
	read -e -p "(默认: 1. HTTP):" new_protocol
	[[ -z "${new_protocol}" ]] && new_protocol="3"
	if [[ ${new_protocol} == "1" ]]; then
		new_protocol="http"
	elif [[ ${new_protocol} == "2" ]]; then
		new_protocol="kcp"
	else
		new_protocol="http"
	fi
	echo && echo "========================"
	echo -e "	协议 : ${Red_background_prefix} ${new_protocol^^} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_conf(){
	Set_port
	Set_passwd
	Set_protocol
	Set_proxy_pass
}
Modify_port(){
	Read_config
	Set_port
	new_passwd="${passwd}"
	new_proxy_pass="${proxy_pass}"
	new_protocol="${protocol}"
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_goflyway
}
Modify_passwd(){
	Read_config
	Set_passwd
	new_port="${port}"
	new_proxy_pass="${proxy_pass}"
	new_protocol="${protocol}"
	Write_config
	Restart_goflyway
}
Modify_proxy_pass(){
	Read_config
	Set_proxy_pass
	new_port="${port}"
	new_passwd="${passwd}"
	new_protocol="${protocol}"
	Write_config
	Restart_goflyway
}
Modify_protocol(){
	Read_config
	Set_protocol
	new_port="${port}"
	new_passwd="${passwd}"
	new_proxy_pass="${proxy_pass}"
	Write_config
	Restart_goflyway
}
Modify_all(){
	Read_config
	Set_conf
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_goflyway
}
Set_goflyway(){
	check_installed_status
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  修改 端口配置
 ${Green_font_prefix}2.${Font_color_suffix}  修改 密码配置
 ${Green_font_prefix}3.${Font_color_suffix}  修改 传输协议
 ${Green_font_prefix}4.${Font_color_suffix}  修改 伪装配置(反向代理)
 ${Green_font_prefix}5.${Font_color_suffix}  修改 全部配置
————————————————
 ${Green_font_prefix}6.${Font_color_suffix}  监控 运行状态
 
 ${Tip} 用户的端口是不能重复的，密码可以重复 !" && echo
	read -e -p "(默认: 取消):" gf_modify
	[[ -z "${gf_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${gf_modify} == "1" ]]; then
		Modify_port
	elif [[ ${gf_modify} == "2" ]]; then
		Modify_passwd
	elif [[ ${gf_modify} == "3" ]]; then
		Modify_protocol
	elif [[ ${gf_modify} == "4" ]]; then
		Modify_proxy_pass
	elif [[ ${gf_modify} == "5" ]]; then
		Modify_all
	elif [[ ${gf_modify} == "6" ]]; then
		Set_crontab_monitor_goflyway
	else
		echo -e "${Error} 请输入正确的数字(1-6)" && exit 1
	fi
}
Install_goflyway(){
	check_root
	[[ -e ${File} ]] && echo -e "${Error} 检测到 GoFlyway 已安装 !" && exit 1
	echo -e "${Info} 开始设置 用户配置..."
	Set_conf
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始检测最新版本..."
	check_new_ver
	echo -e "${Info} 开始下载/安装..."
	Download_goflyway
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_goflyway
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_goflyway
}
Start_goflyway(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} GoFlyway 正在运行，请检查 !" && exit 1
	/etc/init.d/goflyway start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_goflyway
}
Stop_goflyway(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} GoFlyway 没有运行，请检查 !" && exit 1
	/etc/init.d/goflyway stop
}
Restart_goflyway(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/goflyway stop
	/etc/init.d/goflyway start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_goflyway
}
Update_goflyway(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall_goflyway(){
	check_installed_status
	echo "确定要卸载 GoFlyway ? (y/N)"
	echo
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
			chkconfig --del goflyway
		else
			update-rc.d -f goflyway remove
		fi
		rm -rf /etc/init.d/goflyway
		echo && echo "GoFlyway 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_goflyway(){
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
	[[ -z ${proxy_pass} ]] && proxy_pass="无"
	link_qr
	clear && echo "————————————————" && echo
	echo -e " GoFlyway 信息 :" && echo
	echo -e " 地址\t: ${Green_font_prefix}${ip}${Font_color_suffix}"
	echo -e " 端口\t: ${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 密码\t: ${Green_font_prefix}${passwd}${Font_color_suffix}"
	echo -e " 协议\t: ${Green_font_prefix}${protocol^^}${Font_color_suffix}"
	echo -e " 伪装\t: ${Green_font_prefix}${proxy_pass}${Font_color_suffix}"
	echo -e "${link}"
	echo -e "${Tip} 链接仅适用于Windows系统的 Goflyway Tools 客户端（https://doub.io/dbrj-11/）。"
	echo && echo "————————————————"
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n//g;ta'|sed 's/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
link_qr(){
	PWDbase64=$(urlsafe_base64 "${passwd}")
	base64=$(urlsafe_base64 "${ip}:${port}@${PWDbase64}:${protocol}")
	url="goflyway://${base64}"
	QRcode="http://doub.pw/qr/qr.php?text=${url}"
	link=" 链接\t: ${Red_font_prefix}${url}${Font_color_suffix} \n 二维码 : ${Red_font_prefix}${QRcode}${Font_color_suffix} \n "
}
View_Log(){
	check_installed_status
	[[ ! -e ${Log_File} ]] && echo -e "${Error} GoFlyway 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${Log_File}${Font_color_suffix} 命令。" && echo
	tail -f ${Log_File}
}
# 显示 连接信息
debian_View_user_connection_info(){
	format_1=$1
	Read_config
	user_port=${port}
	user_IP_1=$(netstat -anp |grep 'ESTABLISHED' |grep 'goflyway' |grep 'tcp6' |grep ":${user_port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
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
	user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'goflyway' |grep 'tcp' |grep ":${user_port} "|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
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
	read -e -p "(默认: 1):" goflyway_connection_info
	[[ -z "${goflyway_connection_info}" ]] && goflyway_connection_info="1"
	if [[ "${goflyway_connection_info}" == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ "${goflyway_connection_info}" == "2" ]]; then
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
Set_crontab_monitor_goflyway(){
	check_crontab_installed_status
	crontab_monitor_goflyway_status=$(crontab -l|grep "goflyway.sh monitor")
	if [[ -z "${crontab_monitor_goflyway_status}" ]]; then
		echo && echo -e "当前监控模式: ${Green_font_prefix}未开启${Font_color_suffix}" && echo
		echo -e "确定要开启 ${Green_font_prefix}Goflyway 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 Goflyway 服务端)[Y/n]"
		read -e -p "(默认: y):" crontab_monitor_goflyway_status_ny
		[[ -z "${crontab_monitor_goflyway_status_ny}" ]] && crontab_monitor_goflyway_status_ny="y"
		if [[ ${crontab_monitor_goflyway_status_ny} == [Yy] ]]; then
			crontab_monitor_goflyway_cron_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "当前监控模式: ${Green_font_prefix}已开启${Font_color_suffix}" && echo
		echo -e "确定要关闭 ${Green_font_prefix}Goflyway 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 Goflyway 服务端)[y/N]"
		read -e -p "(默认: n):" crontab_monitor_goflyway_status_ny
		[[ -z "${crontab_monitor_goflyway_status_ny}" ]] && crontab_monitor_goflyway_status_ny="n"
		if [[ ${crontab_monitor_goflyway_status_ny} == [Yy] ]]; then
			crontab_monitor_goflyway_cron_stop
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
crontab_monitor_goflyway_cron_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/goflyway.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/goflyway.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "goflyway.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Goflyway 服务端运行状态监控功能 启动失败 !" && exit 1
	else
		echo -e "${Info} Goflyway 服务端运行状态监控功能 启动成功 !"
	fi
}
crontab_monitor_goflyway_cron_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/goflyway.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "goflyway.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Goflyway 服务端运行状态监控功能 停止失败 !" && exit 1
	else
		echo -e "${Info} Goflyway 服务端运行状态监控功能 停止成功 !"
	fi
}
crontab_monitor_goflyway(){
	check_installed_status
	check_pid
	echo "${PID}"
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] 检测到 Goflyway服务端 未运行 , 开始启动..." | tee -a ${Log_File}
		/etc/init.d/goflyway start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Goflyway服务端 启动失败..." | tee -a ${Log_File}
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Goflyway服务端 启动成功..." | tee -a ${Log_File}
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Goflyway服务端 进程运行正常..." | tee -a ${Log_File}
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
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/goflyway.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/goflyway" ]]; then
		rm -rf /etc/init.d/goflyway
		Service_goflyway
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/goflyway.sh" && chmod +x goflyway.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor_goflyway
else
echo && echo -e "  GoFlyway 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/goflyway-jc2 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 GoFlyway
 ${Green_font_prefix} 2.${Font_color_suffix} 升级 GoFlyway
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 GoFlyway
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 GoFlyway
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 GoFlyway
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 GoFlyway
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
	Install_goflyway
	;;
	2)
	Update_goflyway
	;;
	3)
	Uninstall_goflyway
	;;
	4)
	Start_goflyway
	;;
	5)
	Stop_goflyway
	;;
	6)
	Restart_goflyway
	;;
	7)
	Set_goflyway
	;;
	8)
	View_goflyway
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