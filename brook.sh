#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Brook
#	Version: 1.0.2
#	Author: Toyo
#	Blog: https://doub.io/brook-jc3/
#=================================================

sh_ver="1.0.2"
file="/usr/local/brook"
brook_file="/usr/local/brook/brook"
brook_conf="/usr/local/brook/brook.conf"
brook_ver="/usr/local/brook/ver.txt"
brook_log="/usr/local/brook/brook.log"

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
	[[ ! -e ${brook_file} ]] && echo -e "${Error} Brook 没有安装，请检查 !" && exit 1
}
check_pid(){
	PID=`ps -ef| grep "brook"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_new_ver(){
	brook_new_ver=`wget -qO- https://github.com/txthinking/brook/tags| grep "/txthinking/brook/releases/tag/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`
	if [[ -z ${brook_new_ver} ]]; then
		echo -e "${Error} Brook 最新版本获取失败，请手动获取最新版本号[ https://github.com/txthinking/brook/releases ]"
		stty erase '^H' && read -p "请输入版本号 [ 格式是日期 , 如 v20170330 ] :" brook_new_ver
		[[ -z "${brook_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 检测到 Brook 最新版本为 [ ${brook_new_ver} ]"
	fi
}
check_ver_comparison(){
	brook_now_ver=`cat ${brook_ver}`
	[[ -z ${brook_now_ver} ]] && echo "${brook_new_ver}" > ${brook_ver}
	if [[ ${brook_now_ver} != ${brook_new_ver} ]]; then
		echo -e "${Info} 发现 Brook 已有新版本 [ ${brook_new_ver} ]"
		stty erase '^H' && read -p "是否更新 ? [Y/n] :" yn
		[ -z "${yn}" ] && yn="y"
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
	cd ${file}
	if [ ${bit} == "x86_64" ]; then
		wget --no-check-certificate -N "https://github.com/txthinking/brook/releases/download/${brook_new_ver}/brook"
	else
		wget --no-check-certificate -N "https://github.com/txthinking/brook/releases/download/${brook_new_ver}/brook_linux_386"
		mv brook_linux_386 brook
	fi
	[[ ! -e "brook" ]] && echo -e "${Error} Brook 下载失败 !" && exit 1
	chmod +x brook
	echo "${brook_new_ver}" > ${brook_ver}
}
Service_brook(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/brook_centos -O /etc/init.d/brook; then
			echo -e "${Error} Brook服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/brook
		chkconfig --add brook
		chkconfig brook on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/brook_debian -O /etc/init.d/brook; then
			echo -e "${Error} Brook服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/brook
		update-rc.d -f brook defaults
	fi
	echo -e "${Info} Brook服务 管理脚本下载完成 !"
}
Installation_dependency(){
	mkdir ${file}
}
Write_config(){
	cat > ${brook_conf}<<-EOF
port=${bk_port}
passwd=${bk_passwd}
timeout=${bk_timeout}
deadline=${bk_deadline}
music=${bk_music}
EOF
}
Read_config(){
	[[ ! -e ${brook_conf} ]] && echo -e "${Error} Brook 配置文件不存在 !" && exit 1
	port=`cat ${brook_conf}|grep "port"|awk -F "=" '{print $NF}'`
	passwd=`cat ${brook_conf}|grep "passwd"|awk -F "=" '{print $NF}'`
	timeout=`cat ${brook_conf}|grep "timeout"|awk -F "=" '{print $NF}'`
	deadline=`cat ${brook_conf}|grep "deadline"|awk -F "=" '{print $NF}'`
	music=`cat ${brook_conf}|grep "music"|awk -F "=" '{print $NF}'`
}
Set_port(){
	while true
		do
		echo -e "请输入 Brook 监听端口 [1-65535]"
		stty erase '^H' && read -p "(默认: 2333):" bk_port
		[[ -z "$bk_port" ]] && bk_port="2333"
		expr ${bk_port} + 0 &>/dev/null
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
	echo "请输入 Brook 密码"
	stty erase '^H' && read -p "(默认: doub.io):" bk_passwd
	[[ -z "${bk_passwd}" ]] && bk_passwd="doub.io"
	echo && echo "========================"
	echo -e "	密码 : ${Red_background_prefix} ${bk_passwd} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_timeout(){
	while true
		do
		echo -e "请输入 Brook 超时时间（0 代表不限，单位：秒）"
		stty erase '^H' && read -p "(默认: 10):" bk_timeout
		[[ -z "$bk_timeout" ]] && bk_timeout="10"
		if [[ ${bk_timeout} -ge 0 ]] && [[ ${bk_timeout} -le 3600 ]]; then
			echo && echo "========================"
			echo -e "	端口 : ${Red_background_prefix} ${bk_timeout} 秒 ${Font_color_suffix}"
			echo "========================" && echo
			break
		else
			echo "输入错误, 请输入正确的数字。"
		fi
	done
}
Set_deadline(){
	while true
		do
		echo -e "请输入 Brook 连接截止时间（0 代表不限，单位：秒）"
		stty erase '^H' && read -p "(默认: 60):" bk_deadline
		[[ -z "$bk_deadline" ]] && bk_deadline="60"
		if [[ ${bk_deadline} -ge 0 ]] && [[ ${bk_deadline} -le 3600 ]]; then
			echo && echo "========================"
			echo -e "	端口 : ${Red_background_prefix} ${bk_deadline} 秒 ${Font_color_suffix}"
			echo "========================" && echo
			break
		else
			echo "输入错误, 请输入正确的数字。"
		fi
	done
}
Set_music(){
	echo -e "请输入 Brook 音乐（黑人问号？不懂就直接回车
 ${Green_font_prefix}1.${Font_color_suffix} none (不使用)
 ${Green_font_prefix}2.${Font_color_suffix} chinamobile_sdc
 ${Green_font_prefix}3.${Font_color_suffix} chinaunicom_iread
 ${Green_font_prefix}4.${Font_color_suffix} chinaunicom_sales" && echo
	stty erase '^H' && read -p "(默认: 1. none):" bk_music
	[[ -z "${bk_music}" ]] && bk_music="1"
	if [[ ${bk_music} == "1" ]]; then
		bk_music="none"
	elif [[ ${bk_music} == "2" ]]; then
		bk_music="chinamobile_sdc"
	elif [[ ${bk_music} == "3" ]]; then
		bk_music="chinaunicom_iread"
	elif [[ ${bk_music} == "4" ]]; then
		bk_music="chinaunicom_sales"
	else
		bk_music="none"
	fi
	echo && echo "========================"
	echo -e "	音乐 : ${Red_background_prefix} ${bk_music} ${Font_color_suffix}"
	echo "========================" && echo
	[[ ${bk_music} = "none" ]] && bk_music=""
}
Set_conf(){
	Set_port
	Set_passwd
	Set_music
	Set_timeout
	Set_deadline
}
Set_brook(){
	check_installed_status
	check_pid
	Set_conf
	Read_config
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_brook
}
Install_brook(){
	[[ -e ${brook_file} ]] && echo -e "${Error} 检测到 Brook 已安装 !" && exit 1
	echo -e "${Info} 开始设置 用户配置..."
	Set_conf
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
	stty erase '^H' && read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		rm -rf ${file}
		if [[ ${release} = "centos" ]]; then
			chkconfig --del brook
		else
			update-rc.d -f brook remove
		fi
		rm -rf /etc/init.d/brook
		echo && echo "Brook 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_brook(){
	check_installed_status
	Read_config
	ip=`wget -qO- -t1 -T2 ipinfo.io/ip`
	[[ -z ${ip} ]] && ip="VPS_IP"
	[[ -z ${music} ]] && music="无 (客户端留空)"
	clear && echo "————————————————" && echo
	echo -e " Brook 信息 :" && echo
	echo -e " 地址\t: ${Green_font_prefix}${ip}${Font_color_suffix}"
	echo -e " 端口\t: ${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 密码\t: ${Green_font_prefix}${passwd}${Font_color_suffix}"
	echo -e " 音乐\t: ${Green_font_prefix}${music}${Font_color_suffix}"
	echo && echo "————————————————"
}
View_Log(){
	check_installed_status
	[[ ! -e ${brook_log} ]] && echo -e "${Error} Brook 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志(正常情况是没有使用日志记录的)" && echo
	tail -f ${brook_log}
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
	echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- "https://softs.fun/Bash/brook.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="softs"
	[[ -z ${sh_new_ver} ]] && sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/brook.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 检测最新版本失败 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(默认: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			if [[ $sh_new_type == "softs" ]]; then
				wget -N --no-check-certificate https://softs.fun/Bash/brook.sh && chmod +x brook.sh
			else
				wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/brook.sh && chmod +x brook.sh
			fi
			echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "当前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
check_sys
echo && echo -e "  Brook 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/brook-jc3 ----
  
 ${Green_font_prefix}0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 Brook
 ${Green_font_prefix}2.${Font_color_suffix} 升级 Brook
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 Brook
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 启动 Brook
 ${Green_font_prefix}5.${Font_color_suffix} 停止 Brook
 ${Green_font_prefix}6.${Font_color_suffix} 重启 Brook
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 设置 Brook 账号
 ${Green_font_prefix}8.${Font_color_suffix} 查看 Brook 账号
 ${Green_font_prefix}9.${Font_color_suffix} 查看 Brook 日志
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
stty erase '^H' && read -p " 请输入数字 [0-9]:" num
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
	*)
	echo "请输入正确数字 [0-9]"
	;;
esac