#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: ServerStatus client + server
#	Version: 1.0.15
#	Author: Toyo
#	Blog: https://doub.io/shell-jc3/
#=================================================

sh_ver="1.0.15"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/usr/local/ServerStatus"
web_file="/usr/local/ServerStatus/web"
server_file="/usr/local/ServerStatus/server"
server_conf="/usr/local/ServerStatus/server/config.json"
server_conf_1="/usr/local/ServerStatus/server/config.conf"
client_file="/usr/local/ServerStatus/client"
client_log_file="/tmp/serverstatus_client.log"
server_log_file="/tmp/serverstatus_server.log"
jq_file="${file}/jq"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

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
check_installed_server_status(){
	[[ ! -e "${server_file}/sergate" ]] && echo -e "${Error} ServerStatus 服务端没有安装，请检查 !" && exit 1
}
check_installed_client_status(){
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		if [[ ! -e "${file}/status-client.py" ]]; then
			echo -e "${Error} ServerStatus 客户端没有安装，请检查 !" && exit 1
		fi
	fi
}
check_pid_server(){
	PID=`ps -ef| grep "sergate"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_pid_client(){
	PID=`ps -ef| grep "status-client.py"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Download_Server_Status_server(){
	cd "/tmp"
	wget -N --no-check-certificate "https://github.com/ToyoDAdoubi/ServerStatus-Toyo/archive/master.zip"
	[[ ! -e "master.zip" ]] && echo -e "${Error} ServerStatus 服务端下载失败 !" && exit 1
	unzip master.zip
	rm -rf master.zip
	[[ ! -e "/tmp/ServerStatus-Toyo-master" ]] && echo -e "${Error} ServerStatus 服务端解压失败 !" && exit 1
	cd "/tmp/ServerStatus-Toyo-master/server"
	make
	[[ ! -e "sergate" ]] && echo -e "${Error} ServerStatus 服务端编译失败 !" && cd "${file_1}" && rm -rf "/tmp/ServerStatus-Toyo-master" && exit 1
	cd "${file_1}"
	[[ ! -e "${file}" ]] && mkdir "${file}"
	if [[ ! -e "${server_file}" ]]; then
		mkdir "${server_file}"
		mv "/tmp/ServerStatus-Toyo-master/server/sergate" "${server_file}/sergate"
		mv "/tmp/ServerStatus-Toyo-master/web" "${web_file}"
	else
		if [[ -e "${server_file}/sergate" ]]; then
			mv "${server_file}/sergate" "${server_file}/sergate1"
			mv "/tmp/ServerStatus-Toyo-master/server/sergate" "${server_file}/sergate"
		else
			mv "/tmp/ServerStatus-Toyo-master/server/sergate" "${server_file}/sergate"
			mv "/tmp/ServerStatus-Toyo-master/web" "${web_file}"
		fi
	fi
	if [[ ! -e "${server_file}/sergate" ]]; then
		echo -e "${Error} ServerStatus 服务端移动重命名失败 !"
		[[ -e "${server_file}/sergate1" ]] && mv "${server_file}/sergate1" "${server_file}/sergate"
		rm -rf "/tmp/ServerStatus-Toyo-master"
		exit 1
	else
		[[ -e "${server_file}/sergate1" ]] && rm -rf "${server_file}/sergate1"
		rm -rf "/tmp/ServerStatus-Toyo-master"
	fi
}
Download_Server_Status_client(){
	cd "/tmp"
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/ServerStatus-Toyo/master/clients/status-client.py"
	[[ ! -e "status-client.py" ]] && echo -e "${Error} ServerStatus 客户端下载失败 !" && exit 1
	cd "${file_1}"
	[[ ! -e "${file}" ]] && mkdir "${file}"
	if [[ ! -e "${client_file}" ]]; then
		mkdir "${client_file}"
		mv "/tmp/status-client.py" "${client_file}/status-client.py"
	else
		if [[ -e "${client_file}/status-client.py" ]]; then
			mv "${client_file}/status-client.py" "${client_file}/status-client1.py"
			mv "/tmp/status-client.py" "${client_file}/status-client.py"
		else
			mv "/tmp/status-client.py" "${client_file}/status-client.py"
		fi
	fi
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		echo -e "${Error} ServerStatus 客户端移动失败 !"
		[[ -e "${client_file}/status-client1.py" ]] && mv "${client_file}/status-client1.py" "${client_file}/status-client.py"
		rm -rf "/tmp/status-client.py"
		exit 1
	else
		[[ -e "${client_file}/status-client1.py" ]] && rm -rf "${client_file}/status-client1.py"
		rm -rf "/tmp/status-client.py"
	fi
}
Service_Server_Status_server(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/server_status_server_centos" -O /etc/init.d/status-server; then
			echo -e "${Error} ServerStatus 服务端服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/status-server
		chkconfig --add status-server
		chkconfig status-server on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/server_status_server_debian" -O /etc/init.d/status-server; then
			echo -e "${Error} ServerStatus 服务端服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/status-server
		update-rc.d -f status-server defaults
	fi
	echo -e "${Info} ServerStatus 服务端服务管理脚本下载完成 !"
}
Service_Server_Status_client(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/server_status_client_centos" -O /etc/init.d/status-client; then
			echo -e "${Error} ServerStatus 客户端服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/status-client
		chkconfig --add status-client
		chkconfig status-client on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/server_status_client_debian" -O /etc/init.d/status-client; then
			echo -e "${Error} ServerStatus 客户端服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/status-client
		update-rc.d -f status-client defaults
	fi
	echo -e "${Info} ServerStatus 客户端服务管理脚本下载完成 !"
}
Installation_dependency(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		python_status=$(python --help)
		if [[ ${release} == "centos" ]]; then
			yum update
			if [[ -z ${python_status} ]]; then
				yum install -y python unzip vim make
				yum groupinstall "Development Tools" -y
			else
				yum install -y unzip vim make
				yum groupinstall "Development Tools" -y
			fi
		else
			apt-get update
			if [[ -z ${python_status} ]]; then
				apt-get install -y python unzip vim build-essential make
			else
				apt-get install -y unzip vim build-essential make
			fi
		fi
	else
		python_status=$(python --help)
		if [[ ${release} == "centos" ]]; then
			if [[ -z ${python_status} ]]; then
				yum update
				yum install -y python
			fi
		else
			if [[ -z ${python_status} ]]; then
				apt-get update
				apt-get install -y python
			fi
		fi
	fi
}
Write_server_config(){
	cat > ${server_conf}<<-EOF
{"servers":
 [
  {
   "username": "username01",
   "password": "password",
   "name": "Server 01",
   "type": "KVM",
   "host": "",
   "location": "Hong Kong",
   "disabled": false
  }
 ]
}
EOF
}
Write_server_config_conf(){
	cat > ${server_conf_1}<<-EOF
PORT = ${server_port_s}
EOF
}
Read_config_client(){
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		if [[ ! -e "${file}/status-client.py" ]]; then
			echo -e "${Error} ServerStatus 客户端文件不存在 !" && exit 1
		else
			client_text="$(cat "${file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
			rm -rf "${file}/status-client.py"
		fi
	else
		client_text="$(cat "${client_file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
	fi
	client_server="$(echo -e "${client_text}"|grep "SERVER="|awk -F "=" '{print $2}')"
	client_port="$(echo -e "${client_text}"|grep "PORT="|awk -F "=" '{print $2}')"
	client_user="$(echo -e "${client_text}"|grep "USER="|awk -F "=" '{print $2}')"
	client_password="$(echo -e "${client_text}"|grep "PASSWORD="|awk -F "=" '{print $2}')"
}
Read_config_server(){
	if [[ ! -e "${server_conf_1}" ]]; then
		server_port_s="35601"
		Write_server_config_conf
		server_port="35601"
	else
		server_port="$(cat "${server_conf_1}"|grep "PORT = "|awk '{print $3}')"
	fi
}
Set_server(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		echo -e "请输入 ServerStatus 服务端中网站要设置的 域名[server]
默认为本机IP为域名，例如输入: toyoo.pw ，如果要使用本机IP，请留空直接回车"
		read -e -p "(默认: 本机IP):" server_s
		[[ -z "$server_s" ]] && server_s=""
	else
		echo -e "请输入 ServerStatus 服务端的 IP/域名[server]"
		read -e -p "(默认: 127.0.0.1):" server_s
		[[ -z "$server_s" ]] && server_s="127.0.0.1"
	fi
	
	echo && echo "	================================================"
	echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_server_http_port(){
	while true
		do
		echo -e "请输入 ServerStatus 服务端中网站要设置的 域名/IP的端口[1-65535]（如果是域名的话，一般用 80 端口）"
		read -e -p "(默认: 8888):" server_http_port_s
		[[ -z "$server_http_port_s" ]] && server_http_port_s="8888"
		echo $((${server_http_port_s}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${server_http_port_s} -ge 1 ]] && [[ ${server_http_port_s} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	端口: ${Red_background_prefix} ${server_http_port_s} ${Font_color_suffix}"
				echo "	================================================" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	done
}
Set_server_port(){
	while true
		do
		echo -e "请输入 ServerStatus 服务端监听的端口[1-65535]（用于服务端接收客户端消息的端口，客户端要填写这个端口）"
		read -e -p "(默认: 35601):" server_port_s
		[[ -z "$server_port_s" ]] && server_port_s="35601"
		echo $((${server_port_s}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${server_port_s} -ge 1 ]] && [[ ${server_port_s} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	端口: ${Red_background_prefix} ${server_port_s} ${Font_color_suffix}"
				echo "	================================================" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	done
}
Set_username(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		echo -e "请输入 ServerStatus 服务端要设置的用户名[username]（字母/数字，不可与其他账号重复）"
	else
		echo -e "请输入 ServerStatus 服务端中对应配置的用户名[username]（字母/数字，不可与其他账号重复）"
	fi
	read -e -p "(默认: 取消):" username_s
	[[ -z "$username_s" ]] && echo "已取消..." && exit 0
	echo && echo "	================================================"
	echo -e "	账号[username]: ${Red_background_prefix} ${username_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_password(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		echo -e "请输入 ServerStatus 服务端要设置的密码[password]（字母/数字，可重复）"
	else
		echo -e "请输入 ServerStatus 服务端中对应配置的密码[password]（字母/数字）"
	fi
	read -e -p "(默认: doub.io):" password_s
	[[ -z "$password_s" ]] && password_s="doub.io"
	echo && echo "	================================================"
	echo -e "	密码[password]: ${Red_background_prefix} ${password_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_name(){
	echo -e "请输入 ServerStatus 服务端要设置的节点名称[name]（支持中文，前提是你的系统和SSH工具支持中文输入，仅仅是个名字）"
	read -e -p "(默认: Server 01):" name_s
	[[ -z "$name_s" ]] && name_s="Server 01"
	echo && echo "	================================================"
	echo -e "	节点名称[name]: ${Red_background_prefix} ${name_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_type(){
	echo -e "请输入 ServerStatus 服务端要设置的节点虚拟化类型[type]（例如 OpenVZ / KVM）"
	read -e -p "(默认: KVM):" type_s
	[[ -z "$type_s" ]] && type_s="KVM"
	echo && echo "	================================================"
	echo -e "	虚拟化类型[type]: ${Red_background_prefix} ${type_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_location(){
	echo -e "请输入 ServerStatus 服务端要设置的节点位置[location]（支持中文，前提是你的系统和SSH工具支持中文输入）"
	read -e -p "(默认: Hong Kong):" location_s
	[[ -z "$location_s" ]] && location_s="Hong Kong"
	echo && echo "	================================================"
	echo -e "	节点位置[location]: ${Red_background_prefix} ${location_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_config_server(){
	Set_username "server"
	Set_password "server"
	Set_name
	Set_type
	Set_location
}
Set_config_client(){
	Set_server "client"
	Set_server_port
	Set_username "client"
	Set_password "client"
}
Set_ServerStatus_server(){
	check_installed_server_status
	echo && echo -e " 你要做什么？
	
 ${Green_font_prefix} 1.${Font_color_suffix} 添加 节点配置
 ${Green_font_prefix} 2.${Font_color_suffix} 删除 节点配置
————————
 ${Green_font_prefix} 3.${Font_color_suffix} 修改 节点配置 - 节点用户名
 ${Green_font_prefix} 4.${Font_color_suffix} 修改 节点配置 - 节点密码
 ${Green_font_prefix} 5.${Font_color_suffix} 修改 节点配置 - 节点名称
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 节点配置 - 节点虚拟化
 ${Green_font_prefix} 7.${Font_color_suffix} 修改 节点配置 - 节点位置
 ${Green_font_prefix} 8.${Font_color_suffix} 修改 节点配置 - 全部参数
————————
 ${Green_font_prefix} 9.${Font_color_suffix} 启用/禁用 节点配置
————————
 ${Green_font_prefix}10.${Font_color_suffix} 修改 服务端监听端口" && echo
	read -e -p "(默认: 取消):" server_num
	[[ -z "${server_num}" ]] && echo "已取消..." && exit 1
	if [[ ${server_num} == "1" ]]; then
		Add_ServerStatus_server
	elif [[ ${server_num} == "2" ]]; then
		Del_ServerStatus_server
	elif [[ ${server_num} == "3" ]]; then
		Modify_ServerStatus_server_username
	elif [[ ${server_num} == "4" ]]; then
		Modify_ServerStatus_server_password
	elif [[ ${server_num} == "5" ]]; then
		Modify_ServerStatus_server_name
	elif [[ ${server_num} == "6" ]]; then
		Modify_ServerStatus_server_type
	elif [[ ${server_num} == "7" ]]; then
		Modify_ServerStatus_server_location
	elif [[ ${server_num} == "8" ]]; then
		Modify_ServerStatus_server_all
	elif [[ ${server_num} == "9" ]]; then
		Modify_ServerStatus_server_disabled
	elif [[ ${server_num} == "10" ]]; then
		Read_config_server
		Del_iptables "${server_port}"
		Set_server_port
		Write_server_config_conf
		Add_iptables "${server_port_s}"
	else
		echo -e "${Error} 请输入正确的数字[1-10]" && exit 1
	fi
	Restart_ServerStatus_server
}
List_ServerStatus_server(){
	conf_text=$(${jq_file} '.servers' ${server_conf}|${jq_file} ".[]|.username"|sed 's/\"//g')
	conf_text_total=$(echo -e "${conf_text}"|wc -l)
	[[ ${conf_text_total} = "0" ]] && echo -e "${Error} 没有发现 一个节点配置，请检查 !" && exit 1
	conf_text_total_a=$(echo $((${conf_text_total}-1)))
	conf_list_all=""
	for((integer = 0; integer <= ${conf_text_total_a}; integer++))
	do
		now_text=$(${jq_file} '.servers' ${server_conf}|${jq_file} ".[${integer}]"|sed 's/\"//g;s/,$//g'|sed '$d;1d')
		now_text_username=$(echo -e "${now_text}"|grep "username"|awk -F ": " '{print $2}')
		now_text_password=$(echo -e "${now_text}"|grep "password"|awk -F ": " '{print $2}')
		now_text_name=$(echo -e "${now_text}"|grep "name"|grep -v "username"|awk -F ": " '{print $2}')
		now_text_type=$(echo -e "${now_text}"|grep "type"|awk -F ": " '{print $2}')
		now_text_location=$(echo -e "${now_text}"|grep "location"|awk -F ": " '{print $2}')
		now_text_disabled=$(echo -e "${now_text}"|grep "disabled"|awk -F ": " '{print $2}')
		if [[ ${now_text_disabled} == "false" ]]; then
			now_text_disabled_status="${Green_font_prefix}启用${Font_color_suffix}"
		else
			now_text_disabled_status="${Red_font_prefix}禁用${Font_color_suffix}"
		fi
		conf_list_all=${conf_list_all}"用户名: ${Green_font_prefix}"${now_text_username}"${Font_color_suffix} 密码: ${Green_font_prefix}"${now_text_password}"${Font_color_suffix} 节点名: ${Green_font_prefix}"${now_text_name}"${Font_color_suffix} 类型: ${Green_font_prefix}"${now_text_type}"${Font_color_suffix} 位置: ${Green_font_prefix}"${now_text_location}"${Font_color_suffix} 状态: ${Green_font_prefix}"${now_text_disabled_status}"${Font_color_suffix}\n"
	done
	echo && echo -e "节点总数 ${Green_font_prefix}"${conf_text_total}"${Font_color_suffix}"
	echo -e ${conf_list_all}
}
Add_ServerStatus_server(){
	Set_config_server
	Set_username_ch=$(cat ${server_conf}|grep '"username": "'"${username_s}"'"')
	[[ ! -z "${Set_username_ch}" ]] && echo -e "${Error} 用户名已被使用 !" && exit 1
	sed -i '3i\  },' ${server_conf}
	sed -i '3i\   "disabled": false' ${server_conf}
	sed -i '3i\   "location": "'"${location_s}"'",' ${server_conf}
	sed -i '3i\   "host": "'"None"'",' ${server_conf}
	sed -i '3i\   "type": "'"${type_s}"'",' ${server_conf}
	sed -i '3i\   "name": "'"${name_s}"'",' ${server_conf}
	sed -i '3i\   "password": "'"${password_s}"'",' ${server_conf}
	sed -i '3i\   "username": "'"${username_s}"'",' ${server_conf}
	sed -i '3i\  {' ${server_conf}
	echo -e "${Info} 添加节点成功 ${Green_font_prefix}[ 节点名称: ${name_s}, 节点用户名: ${username_s}, 节点密码: ${password_s} ]${Font_color_suffix} !"
}
Del_ServerStatus_server(){
	List_ServerStatus_server
	[[ "${conf_text_total}" = "1" ]] && echo -e "${Error} 节点配置仅剩 1个，不能删除 !" && exit 1
	echo -e "请输入要删除的节点用户名"
	read -e -p "(默认: 取消):" del_server_username
	[[ -z "${del_server_username}" ]] && echo -e "已取消..." && exit 1
	del_username=`cat -n ${server_conf}|grep '"username": "'"${del_server_username}"'"'|awk '{print $1}'`
	if [[ ! -z ${del_username} ]]; then
		del_username_min=$(echo $((${del_username}-1)))
		del_username_max=$(echo $((${del_username}+7)))
		del_username_max_text=$(sed -n "${del_username_max}p" ${server_conf})
		del_username_max_text_last=`echo ${del_username_max_text:((${#del_username_max_text} - 1))}`
		if [[ ${del_username_max_text_last} != "," ]]; then
			del_list_num=$(echo $((${del_username_min}-1)))
			sed -i "${del_list_num}s/,$//g" ${server_conf}
		fi
		sed -i "${del_username_min},${del_username_max}d" ${server_conf}
		echo -e "${Info} 节点删除成功 ${Green_font_prefix}[ 节点用户名: ${del_server_username} ]${Font_color_suffix} "
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Modify_ServerStatus_server_username(){
	List_ServerStatus_server
	echo -e "请输入要修改的节点用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
	Set_username_num=$(cat -n ${server_conf}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_username
		Set_username_ch=$(cat ${server_conf}|grep '"username": "'"${username_s}"'"')
		[[ ! -z "${Set_username_ch}" ]] && echo -e "${Error} 用户名已被使用 !" && exit 1
		sed -i "${Set_username_num}"'s/"username": "'"${manually_username}"'"/"username": "'"${username_s}"'"/g' ${server_conf}
		echo -e "${Info} 修改成功 [ 原节点用户名: ${manually_username}, 新节点用户名: ${username_s} ]"
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Modify_ServerStatus_server_password(){
	List_ServerStatus_server
	echo -e "请输入要修改的节点用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
	Set_username_num=$(cat -n ${server_conf}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_password
		Set_password_num_a=$(echo $((${Set_username_num}+1)))
		Set_password_num_text=$(sed -n "${Set_password_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_password_num_a}"'s/"password": "'"${Set_password_num_text}"'"/"password": "'"${password_s}"'"/g' ${server_conf}
		echo -e "${Info} 修改成功 [ 原节点密码: ${Set_password_num_text}, 新节点密码: ${password_s} ]"
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Modify_ServerStatus_server_name(){
	List_ServerStatus_server
	echo -e "请输入要修改的节点用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
	Set_username_num=$(cat -n ${server_conf}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_name
		Set_name_num_a=$(echo $((${Set_username_num}+2)))
		Set_name_num_a_text=$(sed -n "${Set_name_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_name_num_a}"'s/"name": "'"${Set_name_num_a_text}"'"/"name": "'"${name_s}"'"/g' ${server_conf}
		echo -e "${Info} 修改成功 [ 原节点名称: ${Set_name_num_a_text}, 新节点名称: ${name_s} ]"
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Modify_ServerStatus_server_type(){
	List_ServerStatus_server
	echo -e "请输入要修改的节点用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
	Set_username_num=$(cat -n ${server_conf}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_type
		Set_type_num_a=$(echo $((${Set_username_num}+3)))
		Set_type_num_a_text=$(sed -n "${Set_type_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_type_num_a}"'s/"type": "'"${Set_type_num_a_text}"'"/"type": "'"${type_s}"'"/g' ${server_conf}
		echo -e "${Info} 修改成功 [ 原节点虚拟化: ${Set_type_num_a_text}, 新节点虚拟化: ${type_s} ]"
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Modify_ServerStatus_server_location(){
	List_ServerStatus_server
	echo -e "请输入要修改的节点用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
	Set_username_num=$(cat -n ${server_conf}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_location
		Set_location_num_a=$(echo $((${Set_username_num}+5)))
		Set_location_num_a_text=$(sed -n "${Set_location_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_location_num_a}"'s/"location": "'"${Set_location_num_a_text}"'"/"location": "'"${location_s}"'"/g' ${server_conf}
		echo -e "${Info} 修改成功 [ 原节点位置: ${Set_location_num_a_text}, 新节点位置: ${location_s} ]"
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Modify_ServerStatus_server_all(){
	List_ServerStatus_server
	echo -e "请输入要修改的节点用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
	Set_username_num=$(cat -n ${server_conf}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_username
		Set_password
		Set_name
		Set_type
		Set_location
		sed -i "${Set_username_num}"'s/"username": "'"${manually_username}"'"/"username": "'"${username_s}"'"/g' ${server_conf}
		Set_password_num_a=$(echo $((${Set_username_num}+1)))
		Set_password_num_text=$(sed -n "${Set_password_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_password_num_a}"'s/"password": "'"${Set_password_num_text}"'"/"password": "'"${password_s}"'"/g' ${server_conf}
		Set_name_num_a=$(echo $((${Set_username_num}+2)))
		Set_name_num_a_text=$(sed -n "${Set_name_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_name_num_a}"'s/"name": "'"${Set_name_num_a_text}"'"/"name": "'"${name_s}"'"/g' ${server_conf}
		Set_type_num_a=$(echo $((${Set_username_num}+3)))
		Set_type_num_a_text=$(sed -n "${Set_type_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_type_num_a}"'s/"type": "'"${Set_type_num_a_text}"'"/"type": "'"${type_s}"'"/g' ${server_conf}
		Set_location_num_a=$(echo $((${Set_username_num}+5)))
		Set_location_num_a_text=$(sed -n "${Set_location_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_location_num_a}"'s/"location": "'"${Set_location_num_a_text}"'"/"location": "'"${location_s}"'"/g' ${server_conf}
		echo -e "${Info} 修改成功。"
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Modify_ServerStatus_server_disabled(){
	List_ServerStatus_server
	echo -e "请输入要修改的节点用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "已取消..." && exit 1
	Set_username_num=$(cat -n ${server_conf}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_disabled_num_a=$(echo $((${Set_username_num}+6)))
		Set_disabled_num_a_text=$(sed -n "${Set_disabled_num_a}p" ${server_conf}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		if [[ ${Set_disabled_num_a_text} == "false" ]]; then
			disabled_s="true"
		else
			disabled_s="false"
		fi
		sed -i "${Set_disabled_num_a}"'s/"disabled": '"${Set_disabled_num_a_text}"'/"disabled": '"${disabled_s}"'/g' ${server_conf}
		echo -e "${Info} 修改成功 [ 原禁用状态: ${Set_disabled_num_a_text}, 新禁用状态: ${disabled_s} ]"
	else
		echo -e "${Error} 请输入正确的节点用户名 !" && exit 1
	fi
}
Set_ServerStatus_client(){
	check_installed_client_status
	Set_config_client
	Read_config_client
	Del_iptables_OUT "${client_port}"
	Modify_config_client
	Add_iptables_OUT "${server_port_s}"
	Restart_ServerStatus_client
}
Modify_config_client(){
	sed -i 's/SERVER = "'"${client_server}"'"/SERVER = "'"${server_s}"'"/g' "${client_file}/status-client.py"
	sed -i "s/PORT = ${client_port}/PORT = ${server_port_s}/g" "${client_file}/status-client.py"
	sed -i 's/USER = "'"${client_user}"'"/USER = "'"${username_s}"'"/g' "${client_file}/status-client.py"
	sed -i 's/PASSWORD = "'"${client_password}"'"/PASSWORD = "'"${password_s}"'"/g' "${client_file}/status-client.py"
}
Install_jq(){
	if [[ ! -e ${jq_file} ]]; then
		if [[ ${bit} = "x86_64" ]]; then
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -O ${jq_file}
		else
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux32" -O ${jq_file}
		fi
		[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ解析器 下载失败，请检查 !" && exit 1
		chmod +x ${jq_file}
		echo -e "${Info} JQ解析器 安装完成，继续..." 
	else
		echo -e "${Info} JQ解析器 已安装，继续..."
	fi
}
Install_caddy(){
	echo
	echo -e "${Info} 是否由脚本自动配置HTTP服务(服务端的在线监控网站)，如果选择 N，则请在其他HTTP服务中配置网站根目录为：${Green_font_prefix}${web_file}${Font_color_suffix} [Y/n]"
	read -e -p "(默认: Y 自动部署):" caddy_yn
	[[ -z "$caddy_yn" ]] && caddy_yn="y"
	if [[ "${caddy_yn}" == [Yy] ]]; then
		Set_server "server"
		Set_server_http_port
		if [[ ! -e "/usr/local/caddy/caddy" ]]; then
			wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh
			chmod +x caddy_install.sh
			bash caddy_install.sh install
			rm -rf caddy_install.sh
			[[ ! -e "/usr/local/caddy/caddy" ]] && echo -e "${Error} Caddy安装失败，请手动部署，Web网页文件位置：${Web_file}" && exit 1
		else
			echo -e "${Info} 发现Caddy已安装，开始配置..."
		fi
		if [[ ! -s "/usr/local/caddy/Caddyfile" ]]; then
			cat > "/usr/local/caddy/Caddyfile"<<-EOF
http://${server_s}:${server_http_port_s} {
 root ${web_file}
 timeouts none
 gzip
}
EOF
			/etc/init.d/caddy restart
		else
			echo -e "${Info} 发现 Caddy 配置文件非空，开始追加 ServerStatus 网站配置内容到文件最后..."
			cat >> "/usr/local/caddy/Caddyfile"<<-EOF
http://${server_s}:${server_http_port_s} {
 root ${web_file}
 timeouts none
 gzip
}
EOF
			/etc/init.d/caddy restart
		fi
	else
		echo -e "${Info} 跳过 HTTP服务部署，请手动部署，Web网页文件位置：${web_file} ，如果位置改变，请注意修改服务脚本文件 /etc/init.d/status-server 中的 WEB_BIN 变量 !"
	fi
}
Install_ServerStatus_server(){
	[[ -e "${server_file}/sergate" ]] && echo -e "${Error} 检测到 ServerStatus 服务端已安装 !" && exit 1
	Set_server_port
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency "server"
	Install_caddy
	echo -e "${Info} 开始下载/安装..."
	Download_Server_Status_server
	Install_jq
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_Server_Status_server
	echo -e "${Info} 开始写入 配置文件..."
	Write_server_config
	Write_server_config_conf
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables "${server_port_s}"
	[[ ! -z "${server_http_port_s}" ]] && Add_iptables "${server_http_port_s}"
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_ServerStatus_server
}
Install_ServerStatus_client(){
	[[ -e "${client_file}/status-client.py" ]] && echo -e "${Error} 检测到 ServerStatus 客户端已安装 !" && exit 1
	check_sys
	if [[ ${release} == "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? != 0 ]]; then
			echo -e "${Info} 检测到你的系统为 CentOS6，该系统自带的 Python2.6 版本过低，会导致无法运行客户端，如果你有能力升级为 Python2.7，那么请继续(否则建议更换系统)：[y/N]"
			read -e -p "(默认: N 继续安装):" sys_centos6
			[[ -z "$sys_centos6" ]] && sys_centos6="n"
			if [[ "${sys_centos6}" == [Nn] ]]; then
				echo -e "\n${Info} 已取消...\n"
				exit 1
			fi
		fi
	fi
	echo -e "${Info} 开始设置 用户配置..."
	Set_config_client
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency "client"
	echo -e "${Info} 开始下载/安装..."
	Download_Server_Status_client
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_Server_Status_client
	echo -e "${Info} 开始写入 配置..."
	Read_config_client
	Modify_config_client
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables_OUT "${server_port_s}"
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_ServerStatus_client
}
Update_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	[[ ! -z ${PID} ]] && /etc/init.d/status-server stop
	Download_Server_Status_server
	rm -rf /etc/init.d/status-server
	Service_Server_Status_server
	Start_ServerStatus_server
}
Update_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z ${PID} ]] && /etc/init.d/status-client stop
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		if [[ ! -e "${file}/status-client.py" ]]; then
			echo -e "${Error} ServerStatus 客户端文件不存在 !" && exit 1
		else
			client_text="$(cat "${file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
			rm -rf "${file}/status-client.py"
		fi
	else
		client_text="$(cat "${client_file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
	fi
	server_s="$(echo -e "${client_text}"|grep "SERVER="|awk -F "=" '{print $2}')"
	server_port_s="$(echo -e "${client_text}"|grep "PORT="|awk -F "=" '{print $2}')"
	username_s="$(echo -e "${client_text}"|grep "USER="|awk -F "=" '{print $2}')"
	password_s="$(echo -e "${client_text}"|grep "PASSWORD="|awk -F "=" '{print $2}')"
	Download_Server_Status_client
	Read_config_client
	Modify_config_client
	rm -rf /etc/init.d/status-client
	Service_Server_Status_client
	Start_ServerStatus_client
}
Start_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	[[ ! -z ${PID} ]] && echo -e "${Error} ServerStatus 正在运行，请检查 !" && exit 1
	/etc/init.d/status-server start
}
Stop_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	[[ -z ${PID} ]] && echo -e "${Error} ServerStatus 没有运行，请检查 !" && exit 1
	/etc/init.d/status-server stop
}
Restart_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	[[ ! -z ${PID} ]] && /etc/init.d/status-server stop
	/etc/init.d/status-server start
}
Uninstall_ServerStatus_server(){
	check_installed_server_status
	echo "确定要卸载 ServerStatus 服务端(如果同时安装了客户端，则只会删除服务端) ? [y/N]"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid_server
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config_server
		Del_iptables "${server_port}"
		Save_iptables
		if [[ -e "${client_file}/status-client.py" ]]; then
			rm -rf "${server_file}"
			rm -rf "${web_file}"
		else
			rm -rf "${file}"
		fi
		rm -rf "/etc/init.d/status-server"
		if [[ -e "/etc/init.d/caddy" ]]; then
			/etc/init.d/caddy stop
			wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh
			chmod +x caddy_install.sh
			bash caddy_install.sh uninstall
			rm -rf caddy_install.sh
		fi
		if [[ ${release} = "centos" ]]; then
			chkconfig --del status-server
		else
			update-rc.d -f status-server remove
		fi
		echo && echo "ServerStatus 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
Start_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z ${PID} ]] && echo -e "${Error} ServerStatus 正在运行，请检查 !" && exit 1
	/etc/init.d/status-client start
}
Stop_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ -z ${PID} ]] && echo -e "${Error} ServerStatus 没有运行，请检查 !" && exit 1
	/etc/init.d/status-client stop
}
Restart_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z ${PID} ]] && /etc/init.d/status-client stop
	/etc/init.d/status-client start
}
Uninstall_ServerStatus_client(){
	check_installed_client_status
	echo "确定要卸载 ServerStatus 客户端(如果同时安装了服务端，则只会删除客户端) ? [y/N]"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid_client
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config_client
		Del_iptables_OUT "${client_port}"
		Save_iptables
		if [[ -e "${server_file}/sergate" ]]; then
			rm -rf "${client_file}"
		else
			rm -rf "${file}"
		fi
		rm -rf /etc/init.d/status-client
		if [[ ${release} = "centos" ]]; then
			chkconfig --del status-client
		else
			update-rc.d -f status-client remove
		fi
		echo && echo "ServerStatus 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_ServerStatus_client(){
	check_installed_client_status
	Read_config_client
	clear && echo "————————————————————" && echo
	echo -e "  ServerStatus 客户端配置信息：
 
  IP \t: ${Green_font_prefix}${client_server}${Font_color_suffix}
  端口 \t: ${Green_font_prefix}${client_port}${Font_color_suffix}
  账号 \t: ${Green_font_prefix}${client_user}${Font_color_suffix}
  密码 \t: ${Green_font_prefix}${client_password}${Font_color_suffix}
 
————————————————————"
}
View_client_Log(){
	[[ ! -e ${client_log_file} ]] && echo -e "${Error} 没有找到日志文件 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${client_log_file}${Font_color_suffix} 命令。" && echo
	tail -f ${client_log_file}
}
View_server_Log(){
	[[ ! -e ${erver_log_file} ]] && echo -e "${Error} 没有找到日志文件 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${erver_log_file}${Font_color_suffix} 命令。" && echo
	tail -f ${erver_log_file}
}
Add_iptables_OUT(){
	iptables_ADD_OUT_port=$1
	iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_ADD_OUT_port} -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport ${iptables_ADD_OUT_port} -j ACCEPT
}
Del_iptables_OUT(){
	iptables_DEL_OUT_port=$1
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_DEL_OUT_port} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport ${iptables_DEL_OUT_port} -j ACCEPT
}
Add_iptables(){
	iptables_ADD_IN_port=$1
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_ADD_IN_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${iptables_ADD_IN_port} -j ACCEPT
}
Del_iptables(){
	iptables_DEL_IN_port=$1
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_DEL_IN_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${iptables_DEL_IN_port} -j ACCEPT
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
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/status.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/status-client" ]]; then
		rm -rf /etc/init.d/status-client
		Service_Server_Status_client
	fi
	if [[ -e "/etc/init.d/status-server" ]]; then
		rm -rf /etc/init.d/status-server
		Service_Server_Status_server
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/status.sh" && chmod +x status.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
menu_client(){
echo && echo -e "  ServerStatus 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc3 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 客户端
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 客户端
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 客户端
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 客户端
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 客户端
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 客户端
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 客户端配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 客户端信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 客户端日志
————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 服务端菜单" && echo
if [[ -e "${client_file}/status-client.py" ]]; then
	check_pid_client
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	if [[ -e "${file}/status-client.py" ]]; then
		check_pid_client
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: 客户端 ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
fi
echo
read -e -p " 请输入数字 [0-10]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_ServerStatus_client
	;;
	2)
	Update_ServerStatus_client
	;;
	3)
	Uninstall_ServerStatus_client
	;;
	4)
	Start_ServerStatus_client
	;;
	5)
	Stop_ServerStatus_client
	;;
	6)
	Restart_ServerStatus_client
	;;
	7)
	Set_ServerStatus_client
	;;
	8)
	View_ServerStatus_client
	;;
	9)
	View_client_Log
	;;
	10)
	menu_server
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac
}
menu_server(){
echo && echo -e "  ServerStatus 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc3 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 服务端
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 服务端
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 服务端
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 服务端
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 服务端
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 服务端
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 服务端配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 服务端信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 服务端日志
————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切换为 客户端菜单" && echo
if [[ -e "${server_file}/sergate" ]]; then
	check_pid_server
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: 服务端 ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: 服务端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: 服务端 ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [0-10]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_ServerStatus_server
	;;
	2)
	Update_ServerStatus_server
	;;
	3)
	Uninstall_ServerStatus_server
	;;
	4)
	Start_ServerStatus_server
	;;
	5)
	Stop_ServerStatus_server
	;;
	6)
	Restart_ServerStatus_server
	;;
	7)
	Set_ServerStatus_server
	;;
	8)
	List_ServerStatus_server
	;;
	9)
	View_server_Log
	;;
	10)
	menu_client
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac
}
check_sys
action=$1
if [[ ! -z $action ]]; then
	if [[ $action = "s" ]]; then
		menu_server
	elif [[ $action = "c" ]]; then
		menu_client
	fi
else
	menu_server
fi