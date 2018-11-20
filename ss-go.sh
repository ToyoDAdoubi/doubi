#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Shadowsocks Golang
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/ss-jc67/
#=================================================

sh_ver="1.0.0"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
FOLDER="/usr/local/shadowsocks-go"
FILE="/usr/local/shadowsocks-go/shadowsocks-go"
CONF="/usr/local/shadowsocks-go/shadowsocks-go.conf"
LOG="/usr/local/shadowsocks-go/shadowsocks-go.log"
Now_ver_File="/usr/local/shadowsocks-go/ver.txt"
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
	[[ ! -e ${FILE} ]] && echo -e "${Error} Shadowsocks 没有安装，请检查 !" && exit 1
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
	PID=$(ps -ef| grep "./shadowsocks-go "| grep -v "grep" | grep -v "init.d" |grep -v "service" |awk '{print $2}')
}
check_new_ver(){
	new_ver=$(wget -qO- https://api.github.com/repos/shadowsocks/go-shadowsocks2/releases| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g')
	[[ -z ${new_ver} ]] && echo -e "${Error} Shadowsocks 最新版本获取失败！" && exit 1
	echo -e "${Info} 检测到 Shadowsocks 最新版本为 [ ${new_ver} ]"
}
check_ver_comparison(){
	now_ver=$(cat ${Now_ver_File})
	if [[ "${now_ver}" != "${new_ver}" ]]; then
		echo -e "${Info} 发现 Shadowsocks 已有新版本 [ ${new_ver} ]，旧版本 [ ${now_ver} ]"
		read -e -p "是否更新 ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			\cp "${CONF}" "/tmp/shadowsocks-go.conf"
			rm -rf ${FOLDER}
			Download
			mv "/tmp/shadowsocks-go.conf" "${CONF}"
			Start
		fi
	else
		echo -e "${Info} 当前 Shadowsocks 已是最新版本 [ ${new_ver} ]" && exit 1
	fi
}
Download(){
	if [[ ! -e "${FOLDER}" ]]; then
		mkdir "${FOLDER}"
	else
		[[ -e "${FILE}" ]] && rm -rf "${FILE}"
	fi
	cd "${FOLDER}"
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -N "https://github.com/shadowsocks/go-shadowsocks2/releases/download/${new_ver}/shadowsocks2-linux.gz"
	else
		echo -e "${Error} Shadowsocks-Go版目前不支持 非64位 构架的服务器安装，请更换系统 !" && rm -rf "${FOLDER}" && exit 1
	fi
	[[ ! -e "shadowsocks2-linux.gz" ]] && echo -e "${Error} Shadowsocks 压缩包下载失败 !" && rm -rf "${FOLDER}" && exit 1
	gzip -d "shadowsocks2-linux.gz"
	[[ ! -e "shadowsocks2-linux" ]] && echo -e "${Error} Shadowsocks 压缩包解压失败 !" && rm -rf "${FOLDER}" && exit 1
	mv "shadowsocks2-linux" "shadowsocks-go"
	[[ ! -e "shadowsocks-go" ]] && echo -e "${Error} Shadowsocks 重命名失败 !" && rm -rf "${FOLDER}" && exit 1
	chmod +x shadowsocks-go
	echo "${new_ver}" > ${Now_ver_File}
}
Service(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ss_go_centos" -O /etc/init.d/ss-go; then
			echo -e "${Error} Shadowsocks 服务管理脚本下载失败 !"
			rm -rf "${FOLDER}"
			exit 1
		fi
		chmod +x "/etc/init.d/ss-go"
		chkconfig --add ss-go
		chkconfig ss-go on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ss_go_debian" -O /etc/init.d/ss-go; then
			echo -e "${Error} Shadowsocks 服务管理脚本下载失败 !"
			rm -rf "${FOLDER}"
			exit 1
		fi
		chmod +x "/etc/init.d/ss-go"
		update-rc.d -f ss-go defaults
	fi
	echo -e "${Info} Shadowsocks 服务管理脚本下载完成 !"
}
Installation_dependency(){
	gzip_ver=$(gzip -V)
	if [[ -z ${gzip_ver} ]]; then
		if [[ ${release} == "centos" ]]; then
			yum update
			yum install -y gzip
		else
			apt-get update
			apt-get install -y gzip
		fi
	fi
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
Write_config(){
	cat > ${CONF}<<-EOF
PORT = ${ss_port}
PASSWORD = ${ss_password}
CIPHER = ${ss_cipher}
VERBOSE = ${ss_verbose}
EOF
}
Read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} Shadowsocks 配置文件不存在 !" && exit 1
	port=$(cat ${CONF}|grep 'PORT = '|awk -F 'PORT = ' '{print $NF}')
	password=$(cat ${CONF}|grep 'PASSWORD = '|awk -F 'PASSWORD = ' '{print $NF}')
	cipher=$(cat ${CONF}|grep 'CIPHER = '|awk -F 'CIPHER = ' '{print $NF}')
	verbose=$(cat ${CONF}|grep 'VERBOSE = '|awk -F 'VERBOSE = ' '{print $NF}')
}
Set_port(){
	while true
		do
		echo -e "请输入 Shadowsocks 端口 [1-65535]"
		read -e -p "(默认: 443):" ss_port
		[[ -z "${ss_port}" ]] && ss_port="443"
		echo $((${ss_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${ss_port} -ge 1 ]] && [[ ${ss_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	端口 : ${Red_background_prefix} ${ss_port} ${Font_color_suffix}"
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
	echo "请输入 Shadowsocks 密码 [0-9][a-z][A-Z]"
	read -e -p "(默认: 随机生成):" ss_password
	[[ -z "${ss_password}" ]] && ss_password=$(date +%s%N | md5sum | head -c 16)
	echo && echo "========================"
	echo -e "	密码 : ${Red_background_prefix} ${ss_password} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_cipher(){
	echo -e "请选择 Shadowsocks 加密方式
	
 ${Green_font_prefix} 1.${Font_color_suffix} aes-128-cfb
 ${Green_font_prefix} 2.${Font_color_suffix} aes-128-ctr
 ${Green_font_prefix} 3.${Font_color_suffix} aes-192-cfb
 ${Green_font_prefix} 4.${Font_color_suffix} aes-192-ctr
 ${Green_font_prefix} 5.${Font_color_suffix} aes-256-cfb
 ${Green_font_prefix} 6.${Font_color_suffix} aes-256-ctr
 ${Green_font_prefix} 7.${Font_color_suffix} chacha20-ietf
 ${Green_font_prefix} 8.${Font_color_suffix} xchacha20
 ${Green_font_prefix} 9.${Font_color_suffix} aes-128-gcm            (AEAD)
 ${Green_font_prefix}10.${Font_color_suffix} aes-192-gcm            (AEAD)
 ${Green_font_prefix}11.${Font_color_suffix} aes-256-gcm            (AEAD)
 ${Green_font_prefix}12.${Font_color_suffix} chacha20-ietf-poly1305 (AEAD)

 ${Tip} chacha20 系列加密方式无需额外安装 libsodium，Shadowsocks Go版默认集成 !" && echo
	read -e -p "(默认: 12. chacha20-ietf-poly1305):" ss_cipher
	[[ -z "${ss_cipher}" ]] && ss_cipher="12"
	if [[ ${ss_cipher} == "1" ]]; then
		ss_cipher="aes-128-cfb"
	elif [[ ${ss_cipher} == "2" ]]; then
		ss_cipher="aes-128-ctr"
	elif [[ ${ss_cipher} == "3" ]]; then
		ss_cipher="aes-192-cfb"
	elif [[ ${ss_cipher} == "4" ]]; then
		ss_cipher="aes-192-ctr"
	elif [[ ${ss_cipher} == "5" ]]; then
		ss_cipher="aes-256-cfb"
	elif [[ ${ss_cipher} == "6" ]]; then
		ss_cipher="aes-256-ctr"
	elif [[ ${ss_cipher} == "7" ]]; then
		ss_cipher="chacha20-ietf"
	elif [[ ${ss_cipher} == "8" ]]; then
		ss_cipher="xchacha20"
	elif [[ ${ss_cipher} == "9" ]]; then
		ss_cipher="aead_aes_128_gcm"
	elif [[ ${ss_cipher} == "10" ]]; then
		ss_cipher="aead_aes_192_gcm"
	elif [[ ${ss_cipher} == "11" ]]; then
		ss_cipher="aead_aes_256_gcm"
	elif [[ ${ss_cipher} == "12" ]]; then
		ss_cipher="aead_chacha20_poly1305"
	else
		ss_cipher="aead_chacha20_poly1305"
	fi
	echo && echo "========================"
	echo -e "	加密 : ${Red_background_prefix} ${ss_cipher} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_verbose(){
	echo -e "是否启用详细日志模式？[Y/n]
启用详细日志模式就可以在日志中看到链接者信息(链接时间、链接代理端口、链接者IP、链接者访问的目标域名或IP这些非敏感类信息)。"
	read -e -p "(默认：N 禁用):" ss_verbose
	[[ -z "${ss_verbose}" ]] && ss_verbose="N"
	if [[ "${ss_verbose}" == [Yy] ]]; then
		ss_verbose="YES"
	else
		ss_verbose="NO"
	fi
	echo && echo "========================"
	echo -e "	详细日志模式 : ${Red_background_prefix} ${ss_verbose} ${Font_color_suffix}"
	echo "========================" && echo
}
Set(){
	check_installed_status
	echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  修改 端口配置
 ${Green_font_prefix}2.${Font_color_suffix}  修改 密码配置
 ${Green_font_prefix}3.${Font_color_suffix}  修改 加密配置
 ${Green_font_prefix}4.${Font_color_suffix}  修改 详细日志模式 配置
 ${Green_font_prefix}5.${Font_color_suffix}  修改 全部配置
————————————————
 ${Green_font_prefix}6.${Font_color_suffix}  监控 运行状态" && echo
	read -e -p "(默认: 取消):" ss_modify
	[[ -z "${ss_modify}" ]] && echo "已取消..." && exit 1
	if [[ "${ss_modify}" == "1" ]]; then
		Read_config
		Set_port
		ss_password=${password}
		ss_cipher=${cipher}
		ss_verbose=${verbose}
		Write_config
		Del_iptables
		Add_iptables
		Restart
	elif [[ "${ss_modify}" == "2" ]]; then
		Read_config
		Set_password
		ss_port=${port}
		ss_cipher=${cipher}
		ss_verbose=${verbose}
		Write_config
		Restart
	elif [[ "${ss_modify}" == "3" ]]; then
		Read_config
		Set_cipher
		ss_port=${port}
		ss_password=${password}
		ss_verbose=${verbose}
		Write_config
		Restart
	elif [[ "${ss_modify}" == "4" ]]; then
		Read_config
		Set_verbose
		ss_port=${port}
		ss_password=${password}
		ss_cipher=${cipher}
		Write_config
		Restart
	elif [[ "${ss_modify}" == "5" ]]; then
		Read_config
		Set_port
		Set_password
		Set_cipher
		Set_verbose
		Write_config
		Restart
	elif [[ "${ss_modify}" == "6" ]]; then
		Set_crontab_monitor
	else
		echo -e "${Error} 请输入正确的数字(1-6)" && exit 1
	fi
}
Install(){
	check_root
	[[ -e ${FILE} ]] && echo -e "${Error} 检测到 Shadowsocks 已安装 !" && exit 1
	echo -e "${Info} 开始设置 用户配置..."
	Set_port
	Set_password
	Set_cipher
	Set_verbose
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装..."
	check_new_ver
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
	[[ ! -z ${PID} ]] && echo -e "${Error} Shadowsocks 正在运行，请检查 !" && exit 1
	/etc/init.d/ss-go start
	#sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View
}
Stop(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Shadowsocks 没有运行，请检查 !" && exit 1
	/etc/init.d/ss-go stop
}
Restart(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/ss-go stop
	/etc/init.d/ss-go start
	#sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View
}
Update(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall(){
	check_installed_status
	echo "确定要卸载 Shadowsocks ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		if [[ -e ${CONF} ]]; then
			port=$(cat ${CONF}|grep 'PORT = '|awk -F 'PORT = ' '{print $NF}')
			Del_iptables
			Save_iptables
		fi
		if [[ ! -z $(crontab -l | grep "ss-go.sh monitor") ]]; then
			crontab_monitor_cron_stop
		fi
		rm -rf "${FOLDER}"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del ss-go
		else
			update-rc.d -f ss-go remove
		fi
		rm -rf "/etc/init.d/ss-go"
		echo && echo "Shadowsocks 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
getipv4(){
	ipv4=$(wget -qO- -4 -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ipv4}" ]]; then
		ipv4=$(wget -qO- -4 -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ipv4}" ]]; then
			ipv4=$(wget -qO- -4 -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ipv4}" ]]; then
				ipv4="IPv4_Error"
			fi
		fi
	fi
}
getipv6(){
	ipv6=$(wget -qO- -6 -t1 -T2 ifconfig.co)
	if [[ -z "${ipv6}" ]]; then
		ipv6="IPv6_Error"
	fi
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
ss_link_qr(){
	if [[ "${ipv4}" != "IPv4_Error" ]]; then
		if [[ "${cipher}" == "aead_chacha20_poly1305" ]]; then
			cipher_1="chacha20-ietf-poly1305"
		else
			cipher_1=$(echo "${cipher}"|sed 's/aead_//g;s/_/-/g')
		fi
		SSbase64=$(urlsafe_base64 "${cipher_1}:${password}@${ipv4}:${port}")
		SSurl="ss://${SSbase64}"
		SSQRcode="http://doub.pw/qr/qr.php?text=${SSurl}"
		ss_link_ipv4=" 链接  [ipv4] : ${Red_font_prefix}${SSurl}${Font_color_suffix} \n 二维码[ipv4] : ${Red_font_prefix}${SSQRcode}${Font_color_suffix}"
	fi
	if [[ "${ipv6}" != "IPv6_Error" ]]; then
		if [[ "${cipher}" == "aead_chacha20_poly1305" ]]; then
			cipher_1="chacha20-ietf-poly1305"
		else
			cipher_1=$(echo "${cipher}"|sed 's/aead_//g;s/_/-/g')
		fi
		SSbase64=$(urlsafe_base64 "${cipher_1}:${password}@${ipv6}:${port}")
		SSurl="ss://${SSbase64}"
		SSQRcode="http://doub.pw/qr/qr.php?text=${SSurl}"
		ss_link_ipv6=" 链接  [ipv6] : ${Red_font_prefix}${SSurl}${Font_color_suffix} \n 二维码[ipv6] : ${Red_font_prefix}${SSQRcode}${Font_color_suffix}"
	fi
}
View(){
	check_installed_status
	Read_config
	getipv4
	getipv6
	ss_link_qr
	if [[ "${cipher}" == "aead_chacha20_poly1305" ]]; then
		cipher_2="chacha20-ietf-poly1305"
	else
		cipher_2=$(echo "${cipher}"|sed 's/aead_//g;s/_/-/g')
	fi
	clear && echo
	echo -e "Shadowsocks 用户配置："
	echo -e "————————————————"
	[[ "${ipv4}" != "IPv4_Error" ]] && echo -e " 地址\t: ${Green_font_prefix}${ipv4}${Font_color_suffix}"
	[[ "${ipv6}" != "IPv6_Error" ]] && echo -e " 地址\t: ${Green_font_prefix}${ipv6}${Font_color_suffix}"
	echo -e " 端口\t: ${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 密码\t: ${Green_font_prefix}${password}${Font_color_suffix}"
	echo -e " 加密\t: ${Green_font_prefix}${cipher_2}${Font_color_suffix}"
	[[ ! -z "${ss_link_ipv4}" ]] && echo -e "${ss_link_ipv4}"
	[[ ! -z "${ss_link_ipv6}" ]] && echo -e "${ss_link_ipv6}"
	echo
	echo -e " 详细日志模式\t: ${Green_font_prefix}${verbose}${Font_color_suffix}"
	echo
}
View_Log(){
	check_installed_status
	[[ ! -e ${LOG} ]] && echo -e "${Error} Shadowsocks 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志"
	echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${LOG}${Font_color_suffix} 命令。"
	echo -e "如果想要查看详细日志，请在 [7.设置 账号配置 - 4.修改 详细日志模式 配置] 开启。" && echo
	tail -f ${LOG}
}
# 显示 连接信息
View_user_connection_info_1(){
	format_1=$1
	Read_config
	user_IP=$(ss state connected sport = :${port} -tn|sed '1d'|awk '{print $NF}'|awk -F ':' '{print $(NF-1)}'|sort -u)
	if [[ -z ${user_IP} ]]; then
		user_IP_total="0"
		echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
	else
		user_IP_total=$(echo -e "${user_IP}"|wc -l)
		if [[ ${format_1} == "IP_address" ]]; then
			echo -e "端口: ${Green_font_prefix}"${port}"${Font_color_suffix}\t 链接IP总数: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 当前链接IP: "
			get_IP_address
			echo
		else
			user_IP=$(echo -e "\n${user_IP}")
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
	read -e -p "(默认: 1):" connection_info
	[[ -z "${connection_info}" ]] && connection_info="1"
	if [[ "${connection_info}" == "1" ]]; then
		View_user_connection_info_1
	elif [[ "${connection_info}" == "2" ]]; then
		echo -e "${Tip} 检测IP归属地(ipip.net)，如果IP较多，可能时间会比较长..."
		View_user_connection_info_1 "IP_address"
	else
		echo -e "${Error} 请输入正确的数字(1-2)" && exit 1
	fi
}
get_IP_address(){
	if [[ ! -z ${user_IP} ]]; then
		for((integer_1 = ${user_IP_total}; integer_1 >= 1; integer_1--))
		do
			IP=$(echo "${user_IP}" |sed -n "$integer_1"p)
			IP_address=$(wget -qO- -t1 -T2 http://freeapi.ipip.net/${IP}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g')
			echo -e "${Green_font_prefix}${IP}${Font_color_suffix} (${IP_address})"
			sleep 1s
		done
	fi
}
Set_crontab_monitor(){
	check_crontab_installed_status
	crontab_monitor_status=$(crontab -l|grep "ss-go.sh monitor")
	if [[ -z "${crontab_monitor_status}" ]]; then
		echo && echo -e "当前监控模式: ${Red_font_prefix}未开启${Font_color_suffix}" && echo
		echo -e "确定要开启 ${Green_font_prefix}Shadowsocks 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 Shadowsocks 服务端)[Y/n]"
		read -e -p "(默认: y):" crontab_monitor_status_ny
		[[ -z "${crontab_monitor_status_ny}" ]] && crontab_monitor_status_ny="y"
		if [[ ${crontab_monitor_status_ny} == [Yy] ]]; then
			crontab_monitor_cron_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "当前监控模式: ${Green_font_prefix}已开启${Font_color_suffix}" && echo
		echo -e "确定要关闭 ${Red_font_prefix}Shadowsocks 服务端运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 Shadowsocks 服务端)[y/N]"
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
	sed -i "/ss-go.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/ss-go.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "ss-go.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Shadowsocks 服务端运行状态监控功能 启动失败 !" && exit 1
	else
		echo -e "${Info} Shadowsocks 服务端运行状态监控功能 启动成功 !"
	fi
}
crontab_monitor_cron_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/ss-go.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "ss-go.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Shadowsocks 服务端运行状态监控功能 停止失败 !" && exit 1
	else
		echo -e "${Info} Shadowsocks 服务端运行状态监控功能 停止成功 !"
	fi
}
crontab_monitor(){
	check_installed_status
	check_pid
	#echo "${PID}"
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] 检测到 Shadowsocks服务端 未运行 , 开始启动..." | tee -a ${LOG}
		/etc/init.d/ss-go start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Shadowsocks服务端 启动失败..." | tee -a ${LOG}
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Shadowsocks服务端 启动成功..." | tee -a ${LOG}
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Shadowsocks服务端 进程运行正常..." | tee -a ${LOG}
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ss_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ss_port} -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ss_port} -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport ${ss_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
		chkconfig --level 2345 iptables on
		chkconfig --level 2345 ip6tables on
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ss-go.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/ss-go" ]]; then
		rm -rf /etc/init.d/ss-go
		Service
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ss-go.sh" && chmod +x ss-go.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor
else
	echo && echo -e "  Shadowsocks-Go 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/ss-jc67 ----
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 Shadowsocks
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 Shadowsocks
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 Shadowsocks
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 Shadowsocks
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 Shadowsocks
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 Shadowsocks
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 账号配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 账号信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 日志信息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 链接信息
————————————" && echo
	if [[ -e ${FILE} ]]; then
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
		View
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