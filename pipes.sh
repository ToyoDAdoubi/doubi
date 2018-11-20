#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#       System Required: CentOS/Debian/Ubuntu
#       Description: PipeSocks
#       Version: 1.0.5
#       Author: Toyo
#       Blog: https://doub.io/pipesocks-jc1/
#       Github: https://github.com/pipesocks/install
#=================================================
pipes_file="/usr/local/pipesocks"
pipes_ver="/usr/local/pipesocks/ver.txt"
pipes_log="/usr/local/pipesocks/pipesocks.log"
pipes_config_file="/etc/pipesocks"
pipes_config="/etc/pipesocks/pipesocks.conf"
Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"

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
	[[ ! -e ${pipes_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 没有安装，请检查 !" && exit 1
}
check_new_ver(){
	#pipes_new_ver=`curl -m 10 -s "https://pipesocks.github.io/js/index.js" | sed -n "15p" | awk -F ": " '{print $NF}' | sed 's/"//g;s/,//g'`
	pipes_new_ver=`wget -qO- "https://pipesocks.github.io/dist.json" | sed -n "15p" | awk -F ": " '{print $NF}' | sed 's/"//g;s/,//g'`
	[[ -z ${pipes_new_ver} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 最新版本获取失败 !" && exit 1
}
check_ver_comparison(){
	pipes_now_ver=`cat ${pipes_ver}`
	if [[ ${pipes_now_ver} != "" ]]; then
		if [[ ${pipes_now_ver} != ${pipes_new_ver} ]]; then
			echo -e "${Info_font_prefix}[信息]${Font_suffix} 发现 PipeSocks 已有新版本 [v${pipes_new_ver}] !"
			read -e -p "是否更新 ? [Y/n] :" yn
			[[ -z "${yn}" ]] && yn="y"
			if [[ $yn == [Yy] ]]; then
				PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'` && [[ ! -z $PID ]] && kill -9 ${PID}
				Download_pipes
				Read_config
				Start_pipes
			fi
		else
			echo -e "${Info_font_prefix}[信息]${Font_suffix} 当前 PipeSocks 已是最新版本 [v${pipes_new_ver}] !" && exit 1
		fi
	else
		echo "${pipes_new_ver}" > ${pipes_ver}
		echo -e "${Info_font_prefix}[信息]${Font_suffix} 当前 PipeSocks 已是最新版本 [v${pipes_new_ver}] !" && exit 1
	fi
}
Download_pipes(){
	cd "/usr/local"
	if [[ ${bit} == "x86_64" ]]; then
		#wget -O "pipesocks-linux.tar.xz" "https://coding.net/u/yvbbrjdr/p/pipesocks-release/git/raw/master/pipesocks-${pipes_new_ver}-linux.tar.xz"
		wget --no-check-certificate -O "pipesocks-linux.tar.xz" "https://github.com/pipesocks/pipesocks/releases/download/${pipes_new_ver}/pipesocks-${pipes_new_ver}-linux.tar.xz"
	else
		echo -e "${Error_font_prefix}[错误]${Font_suffix} 不支持 ${bit} !" && exit 1
	fi
	[[ ! -e "pipesocks-linux.tar.xz" ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 下载失败 !" && exit 1
	[[ -e ${pipes_file} ]] && rm -rf ${pipes_file}
	tar -xJf pipesocks-linux.tar.xz && rm -rf pipesocks-linux.tar.xz
	[[ ! -e ${pipes_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 解压失败或压缩文件不完整 !" && exit 1
	mv pipesocks pipes
	mkdir pipesocks/
	mv pipes pipesocks/pipesocks
	cd ${pipes_file}
	echo "${pipes_new_ver}" > ${pipes_ver}
}
Service_pipes(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/pipes_centos -O /etc/init.d/pipes; then
			echo -e "${Error} ShadowsocksR服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/pipes
		chkconfig --add pipes
		chkconfig pipes on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/pipes_debian -O /etc/init.d/pipes; then
			echo -e "${Error} ShadowsocksR服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/pipes
		update-rc.d -f pipes defaults
	fi
	echo -e "${Info} ShadowsocksR服务 管理脚本下载完成 !"
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${pipes_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${pipes_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${pump_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${pump_port} -j ACCEPT
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
Write_config(){
	if [[ ! -e ${pipes_config} ]]; then
		[[ ! -e ${pipes_config_file} ]] && mkdir ${pipes_config_file}
	fi
	cat > ${pipes_config}<<-EOF
pump_port=${pipes_port}
pump_passwd=${pipes_passwd}
EOF
}
Read_config(){
	[[ ! -e ${pipes_config} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 配置文件不存在 !" && exit 1
	pump_port=`cat ${pipes_config}|grep "pump_port"|awk -F "=" '{print $NF}'`
	pump_passwd=`cat ${pipes_config}|grep "pump_passwd"|awk -F "=" '{print $NF}'`
}
Set_user_pipes(){
	while true
		do
		echo -e "请输入 PipeSocks 本地监听端口 [1-65535]"
		read -e -p "(默认: 2333):" pipes_port
		[[ -z "$pipes_port" ]] && pipes_port="2333"
		echo $((${pipes_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${pipes_port} -ge 1 ]] && [[ ${pipes_port} -le 65535 ]]; then
				echo && echo "————————————————————"
				echo -e "	端口 : ${Info_font_prefix} ${pipes_port}${Font_suffix}"
				echo "————————————————————" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	done
	echo "请输入 PipeSocks 密码"
	read -e -p "(默认: doub.io):" pipes_passwd
	[[ -z "${pipes_passwd}" ]] && pipes_passwd="doub.io"
	echo && echo "————————————————————"
	echo -e "	密码 : ${Info_font_prefix}${pipes_passwd}${Font_suffix}"
	echo "————————————————————" && echo
}
Set_pipes(){
	check_installed_status 
	Set_user_pipes
	Read_config
	Del_iptables
	Add_iptables
	Save_iptables
	Write_config
	Restart_pipes
}
View_pipes(){
	check_installed_status
	Read_config
	ip=`wget -qO- -t1 -T2 ipinfo.io/ip`
	[[ -z ${ip} ]] && ip="VPS_IP"
	clear && echo "————————————————" && echo
	echo -e " 你的 PipeSocks 账号信息 :" && echo
	echo -e " I  P\t: ${Info_font_prefix}${ip}${Font_suffix}"
	echo -e " 端口\t: ${Info_font_prefix}${pump_port}${Font_suffix}"
	echo -e " 密码\t: ${Info_font_prefix}${pump_passwd}${Font_suffix}"
	echo && echo "————————————————"
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e " 当前状态: ${Info_font_prefix}正在运行${Font_suffix}"
	else
		echo -e " 当前状态: ${Error_font_prefix}没有运行${Font_suffix}"
	fi
	echo
}
Install_pipes(){
	[[ -e ${pipes_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} 检测到 PipeSocks 已安装，如需继续，请先卸载 !" && exit 1
	check_new_ver
	Set_user_pipes
	Download_pipes
	Service_pipes
	Write_config
	Set_iptables
	Add_iptables
	Save_iptables
	Start_pipes
}
Update_pipes(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Start_pipes(){
	check_installed_status
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'`
	[[ ! -z $PID ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 进程正在运行，请检查 !" && exit 1
	/etc/init.d/pipes start
}
Stop_pipes(){
	check_installed_status
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'`
	[[ -z $PID ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} 没有发现 PipeSocks 进程运行，请检查 !" && exit 1
	/etc/init.d/pipes stop
}
Restart_pipes(){
	check_installed_status
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		/etc/init.d/pipes stop
	fi
	/etc/init.d/pipes start
}
Log_pipes(){
	check_installed_status
	[[ ! -e ${pipes_log} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 日志文件不存在 !" && exit 1
	echo && echo -e "使用 ${Info_background_prefix} Ctrl+C ${Font_suffix} 键退出查看日志 !" && echo -e "如果需要查看完整日志内容，请用 ${Info_background_prefix}cat ${pipes_log}${Font_suffix} 命令。" && echo
	tail -f ${pipes_log}
}
Uninstall_pipes(){
	check_installed_status
	echo "确定要卸载 PipeSocks ? [y/N]" && echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'`
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		Save_iptables
		if [[ ${release} = "centos" ]]; then
			chkconfig --del pipes
		else
			update-rc.d -f pipes remove
		fi
		rm -rf /etc/init.d/pipes
		rm -rf ${pipes_file} && rm -rf  ${pipes_config_file}
		echo && echo "PipeSocks 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
check_sys
echo && echo "请输入一个数字来选择选项" && echo
echo -e " 1. 安装 PipeSocks"
echo -e " 2. 升级 PipeSocks"
echo -e " 3. 卸载 PipeSocks"
echo "————————————"
echo -e " 4. 启动 PipeSocks"
echo -e " 5. 停止 PipeSocks"
echo -e " 6. 重启 PipeSocks"
echo "————————————"
echo -e " 7. 设置 PipeSocks 账号"
echo -e " 8. 查看 PipeSocks 账号"
echo -e " 9. 查看 PipeSocks 日志"
echo "————————————" && echo
if [[ -e ${pipes_file} ]]; then
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'`
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Info_font_prefix}已安装${Font_suffix} 并 ${Info_font_prefix}已启动${Font_suffix}"
	else
		echo -e " 当前状态: ${Info_font_prefix}已安装${Font_suffix} 但 ${Error_font_prefix}未启动${Font_suffix}"
	fi
else
	echo -e " 当前状态: ${Error_font_prefix}未安装${Font_suffix}"
fi
echo
read -e -p " 请输入数字 [1-9]:" num
case "$num" in
	1)
	Install_pipes
	;;
	2)
	Update_pipes
	;;
	3)
	Uninstall_pipes
	;;
	4)
	Start_pipes
	;;
	5)
	Stop_pipes
	;;
	6)
	Restart_pipes
	;;
	7)
	Set_pipes
	;;
	8)
	View_pipes
	;;
	9)
	Log_pipes
	;;
	*)
	echo "请输入正确数字 [1-9]"
	;;
esac