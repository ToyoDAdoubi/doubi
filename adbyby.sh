#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: ADbyby
#	Version: 1.0.1
#	Author: Toyo
#	Blog: https://doub.io/adbyby-jc2/
#=================================================

file="/usr/local/adbyby"
adbyby_file="/usr/local/adbyby/bin/adbyby"
adbyby_conf="/usr/local/adbyby/bin/adhook.ini"

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
check_installed_status(){
	[[ ! -e ${adbyby_file} ]] && echo -e "${Error} ADbyby 没有安装，请检查 !" && exit 1
}
check_pid(){
	PID=`ps -ef| grep "adbyby"| grep -v grep| grep -v "adbyby.sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Download_adbyby(){
	cd ${file}
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -O "adbyby.tar.gz" "https://raw.githubusercontent.com/adbyby/Files/master/linux.64.tar.gz"
	else
		wget --no-check-certificate -O "adbyby.tar.gz" "https://raw.githubusercontent.com/adbyby/Files/master/linux.86.tar.gz"
	fi
	[[ ! -e "adbyby.tar.gz" ]] && echo -e "${Error} ADbyby 下载失败 !" && exit 1
	tar -xzf adbyby.tar.gz && rm -rf adbyby.tar.gz
	[[ ! -e "${adbyby_file}" ]] && echo -e "${Error} ADbyby 解压失败 !" && exit 1
	cd bin
	chmod 777 adbyby
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/adhook.ini"
}
Service_adbyby(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/adbyby_centos -O /etc/init.d/adbyby; then
			echo -e "${Error} ADbyby服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/adbyby
		chkconfig --add adbyby
		chkconfig adbyby on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/adbyby_debian -O /etc/init.d/adbyby; then
			echo -e "${Error} ADbyby服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/adbyby
		update-rc.d -f adbyby defaults
	fi
	echo -e "${Info} ADbyby服务 管理脚本下载完成 !"
}
Installation_dependency(){
	if [[ ${release} = "centos" ]]; then
		yum update
		yum install -y vim
	else
		apt-get update
		apt-get install -y vim
	fi
	mkdir ${file}
}
Install_adbyby(){
	[[ -e ${adbyby_file} ]] && echo -e "${Error} 检测到 ADbyby 已安装 !" && exit 1
	check_sys
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装..."
	Download_adbyby
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_adbyby
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_adbyby
}
Start_adbyby(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} ADbyby 正在运行，请检查 !" && exit 1
	service adbyby start
}
Stop_adbyby(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} ADbyby 没有运行，请检查 !" && exit 1
	service adbyby stop
}
Restart_adbyby(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && service adbyby stop
	service adbyby start
}
Set_adbyby(){
	check_installed_status
	vi ${adbyby_conf}
	Restart_adbyby
}
Uninstall_adbyby(){
	check_installed_status
	echo "确定要卸载 ADbyby ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Del_iptables
		Save_iptables
		rm -rf ${file} && rm -rf /etc/init.d/adbyby
		if [[ ${release} = "centos" ]]; then
			chkconfig --del adbyby
		else
			update-rc.d -f adbyby remove
		fi
		echo && echo "ADbyby 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
Add_iptables(){
	iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8118
}
Del_iptables(){
	iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8118
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	sysctl -p
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
echo && echo -e "请输入一个数字来选择选项

 ${Green_font_prefix}1.${Font_color_suffix} 安装 ADbyby
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 ADbyby
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 ADbyby
 ${Green_font_prefix}4.${Font_color_suffix} 停止 ADbyby
 ${Green_font_prefix}5.${Font_color_suffix} 重启 ADbyby
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 修改 配置文件
————————————" && echo
if [[ -e ${adbyby_file} ]]; then
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
read -e -p " 请输入数字 [1-8]:" num
case "$num" in
	1)
	Install_adbyby
	;;
	2)
	Uninstall_adbyby
	;;
	3)
	Start_adbyby
	;;
	4)
	Stop_adbyby
	;;
	5)
	Restart_adbyby
	;;
	6)
	Set_adbyby
	;;
	*)
	echo "请输入正确数字 [1-8]"
	;;
esac