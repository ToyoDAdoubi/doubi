#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Peerflix Server
#	Version: 1.1.0
#	Author: Toyo
#	Blog: https://doub.io/wlzy-13/
#=================================================

sh_ver="1.1.0"
node_ver="v8.11.3"
node_file="/etc/node"
ps_file="/etc/node/lib/node_modules/peerflix-server"
conf_file="/etc/peerflix-server"
ps_conf="/etc/peerflix-server/peerflix-server.conf"
ps_log="/tmp/peerflix-server.log"
bt_port="6881"

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
	bit=$(uname -m)
}
check_installed_status(){
	[[ ! -e ${ps_file} ]] && echo -e "${Error} Peerflix Server 没有安装，请检查 !" && exit 1
}
check_pid(){
	PID=$(ps -ef | grep peerflix-server | grep -v grep |grep -v "init.d" |grep -v "service" |awk '{print $2}')
}
Download_ps(){
	echo -e "${Info} 开始安装 node-js ..."
	if [[ ! -e ${node_file} ]]; then
		cd /tmp
		if [[ ${bit} == "x86_64" ]]; then
			node_name="node-${node_ver}-linux-x64"
			wget --no-check-certificate -O node.tar.xz "https://nodejs.org/dist/${node_ver}/node-${node_ver}-linux-x64.tar.xz"
		else
			node_name="node-${node_ver}-linux-x86"
			wget --no-check-certificate -O node.tar.xz "https://nodejs.org/dist/${node_ver}/node-${node_ver}-linux-x86.tar.xz"
		fi
		[[ ! -e "node.tar.xz" ]] && echo -e "${Error} Peerflix Server 压缩包下载失败 !" && Download_shanhou 0
		xz -d node.tar.xz
		[[ ! -e "node.tar" ]] && echo -e "${Error} Peerflix Server 解压失败(可能是 压缩包损坏 或者 没有安装 XZ) !" && Download_shanhou 1
		tar -xvf "node.tar" -C "/etc"
		[[ ! -e "node.tar" ]] && echo -e "${Error} Peerflix Server 解压失败(可能是 压缩包损坏 或者 没有安装 Tar) !" && Download_shanhou 2
		mv "/etc/${node_name}" ${node_file}
		[[ ! -e "${node_file}" ]] && echo -e "${Error} Peerflix Server 文件夹重命名失败!" && Download_shanhou 4
		rm -rf "/tmp/node.tar.xz"
		rm -rf "/tmp/node.tar"
		ln -s ${node_file}/bin/node /usr/local/bin/node
		ln -s ${node_file}/bin/npm /usr/local/bin/npm
		echo -e "${Info} node-js 安装完成，开始安装 peerflix-server ..."
	else
		echo -e "${Info} node-js 已安装，开始安装 peerflix-server ..."
	fi
	
	npm install -g peerflix-server
	if [[ ! -e ${ps_file} ]]; then
		echo -e "${Error} Peerflix Server 安装失败，请检查 !" && exit 1
	else
		echo -e "${Info} Peerflix Server 安装成功，继续..."
	fi
}
Download_shanhou(){
	if [[ $1 == 0 ]]; then
		rm -rf ${conf_file}
	elif [[ $1 == 1 ]]; then
		rm -rf ${conf_file}
		rm -rf "/tmp/node.tar.xz"
	elif [[ $1 == 2 ]]; then
		rm -rf ${conf_file}
		rm -rf "/tmp/node.tar.xz"
		rm -rf "/tmp/node.tar"
	elif [[ $1 == 3 ]]; then
		rm -rf ${conf_file}
		rm -rf "/tmp/node.tar.xz"
		rm -rf "/tmp/node.tar"
		rm -rf "/etc/node-${node_ver}-linux-x64"
	elif [[ $1 == 4 ]]; then
		rm -rf ${conf_file}
		rm -rf "/tmp/node.tar.xz"
		rm -rf "/tmp/node.tar"
		rm -rf "/etc/node-${node_ver}-linux-x86"
	fi
	exit 1
}
Service_ps(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/pserver_centos" -O /etc/init.d/pserver; then
			echo -e "${Error} Peerflix Server服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/pserver
		chkconfig --add pserver
		chkconfig pserver on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/pserver_debian" -O /etc/init.d/pserver; then
			echo -e "${Error} Peerflix Server服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/pserver
		update-rc.d -f pserver defaults
	fi
	echo -e "${Info} Peerflix Server服务 管理脚本下载完成 !"
}
Installation_dependency(){
	xz_ver=$(xz -V)
	tar_ver=$(tar --version)
	[[ -z ${xz_ver} ]] && pack_name="xz "
	[[ -z ${tar_ver} ]] && pack_name="${pack_name}tar"
	if [[ ! -z ${pack_name} ]]; then
		if [[ ${release} == "centos" ]]; then
			yum update
			yum install -y ${pack_name}
		else
			apt-get update
			apt-get install -y ${pack_name}
		fi
	fi
	mkdir "${conf_file}"
}
Write_config(){
	echo -e "port = ${ps_port}" > ${ps_conf}
}
Read_config(){
	[[ ! -e ${ps_conf} ]] && echo -e "${Error} Peerflix Server 配置文件不存在 !" && exit 1
	port=`cat ${ps_conf}|grep "port = "|awk -F "port = " '{print $NF}'`
}
Set_port(){
	while true
		do
		echo -e "请输入 Peerflix Server 监听端口 [1-65535]（如果是绑定的域名，那么建议80端口）"
		read -e -p "(默认端口: 9000):" ps_port
		[[ -z "${ps_port}" ]] && ps_port="9000"
		echo $((${ps_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${ps_port} -ge 1 ]] && [[ ${ps_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	端口 : ${Red_background_prefix} ${ps_port} ${Font_color_suffix}"
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
Set_ps(){
	check_installed_status
	Set_port
	Read_config
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_ps
}
Install_ps(){
	check_root
	[[ -e ${ps_file} ]] && echo -e "${Error} 检测到 Peerflix Server 已安装 !" && exit 1
	check_sys
	echo -e "${Info} 开始设置 用户配置..."
	Set_port
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装..."
	Download_ps
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_ps
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_ps
}
Start_ps(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Peerflix Server 正在运行，请检查 !" && exit 1
	/etc/init.d/pserver start
}
Stop_ps(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Peerflix Server 没有运行，请检查 !" && exit 1
	/etc/init.d/pserver stop
}
Restart_ps(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/pserver stop
	/etc/init.d/pserver start
}
Log_ps(){
	[[ ! -e "${ps_log}" ]] && echo -e "${Error} Peerflix Server 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${ps_log}${Font_color_suffix} 命令。" && echo
	tail -f "${ps_log}"
}
Uninstall_ps(){
	check_installed_status
	echo "确定要卸载 Peerflix Server ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		port=`cat ${ps_conf}|grep "port = "|awk -F "port = " '{print $NF}'`
		Del_iptables
		
		rm -rf /usr/local/bin/node
		rm -rf /usr/local/bin/npm
		rm -rf ${node_file}
		rm -rf ${conf_file}
		rm -rf /etc/init.d/pserver
		if [[ ${release} = "centos" ]]; then
			chkconfig --del pserver
		else
			update-rc.d -f pserver remove
		fi
		echo && echo "Peerflix Server 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_ps(){
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
	clear && echo "————————————————" && echo
	echo -e " Peerflix Server 信息 :" && echo
	echo -e " 地址\t: ${Green_font_prefix}http://${ip}:${port}${Font_color_suffix}"
	echo && echo "————————————————"
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ps_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ps_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${bt_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${bt_port} -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport ${bt_port} -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport ${bt_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${bt_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${bt_port} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport ${bt_port} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport ${bt_port} -j ACCEPT
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
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/pserver.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/pserver" ]]; then
		rm -rf /etc/init.d/pserver
		Service_ps
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/pserver.sh" && chmod +x pserver.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
echo && echo -e "  Peerflix Server 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/wlzy-13/ ----
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本

 ${Green_font_prefix}1.${Font_color_suffix} 安装 Peerflix Server
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 Peerflix Server
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 Peerflix Server
 ${Green_font_prefix}4.${Font_color_suffix} 停止 Peerflix Server
 ${Green_font_prefix}5.${Font_color_suffix} 重启 Peerflix Server
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 设置 Peerflix Server 端口
 ${Green_font_prefix}7.${Font_color_suffix} 查看 Peerflix Server 信息
 ${Green_font_prefix}8.${Font_color_suffix} 查看 Peerflix Server 日志
————————————" && echo
if [[ -e ${ps_file} ]]; then
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
read -e -p " 请输入数字 [0-8]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_ps
	;;
	2)
	Uninstall_ps
	;;
	3)
	Start_ps
	;;
	4)
	Stop_ps
	;;
	5)
	Restart_ps
	;;
	6)
	Set_ps
	;;
	7)
	View_ps
	;;
	8)
	Log_ps
	;;
	*)
	echo "请输入正确数字 [0-8]"
	;;
esac