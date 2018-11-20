#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#       System Required: CentOS/Debian/Ubuntu
#       Description: Caddy Install
#       Version: 1.0.8
#       Author: Toyo
#       Blog: https://doub.io/shell-jc1/
#=================================================
file="/usr/local/caddy/"
caddy_file="/usr/local/caddy/caddy"
caddy_conf_file="/usr/local/caddy/Caddyfile"
Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
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
	[[ ! -e ${caddy_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 没有安装，请检查 !" && exit 1
}
Download_caddy(){
	[[ ! -e ${file} ]] && mkdir "${file}"
	cd "${file}"
	PID=$(ps -ef |grep "caddy" |grep -v "grep" |grep -v "init.d" |grep -v "service" |grep -v "caddy_install" |awk '{print $2}')
	[[ ! -z ${PID} ]] && kill -9 ${PID}
	[[ -e "caddy_linux*.tar.gz" ]] && rm -rf "caddy_linux*.tar.gz"
	
	if [[ ! -z ${extension} ]]; then
		extension_all="?plugins=${extension}&license=personal"
	else
		extension_all="?license=personal"
	fi
	
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -O "caddy_linux.tar.gz" "https://caddyserver.com/download/linux/amd64${extension_all}"
	elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
		wget --no-check-certificate -O "caddy_linux.tar.gz" "https://caddyserver.com/download/linux/386${extension_all}"
	elif [[ ${bit} == "armv7l" ]]; then
		wget --no-check-certificate -O "caddy_linux.tar.gz" "https://caddyserver.com/download/linux/arm7${extension_all}"
	else
		echo -e "${Error_font_prefix}[错误]${Font_suffix} 不支持 [${bit}] ! 请向本站反馈[]中的名称，我会看看是否可以添加支持。" && exit 1
	fi
	[[ ! -e "caddy_linux.tar.gz" ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 下载失败 !" && exit 1
	tar zxf "caddy_linux.tar.gz"
	rm -rf "caddy_linux.tar.gz"
	[[ ! -e ${caddy_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 解压失败或压缩文件错误 !" && exit 1
	rm -rf LICENSES.txt
	rm -rf README.txt 
	rm -rf CHANGES.txt
	rm -rf "init/"
	chmod +x caddy
}
Service_caddy(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/caddy_centos -O /etc/init.d/caddy; then
			echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/caddy
		chkconfig --add caddy
		chkconfig caddy on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/caddy_debian -O /etc/init.d/caddy; then
			echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/caddy
		update-rc.d -f caddy defaults
	fi
}
install_caddy(){
	check_root
	if [[ -e ${caddy_file} ]]; then
		echo && echo -e "${Error_font_prefix}[信息]${Font_suffix} 检测到 Caddy 已安装，是否继续安装(覆盖更新)？[y/N]"
		read -e -p "(默认: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Nn] ]]; then
			echo && echo "已取消..." && exit 1
		fi
	fi
	Download_caddy
	Service_caddy
	echo && echo -e " Caddy 使用命令：${caddy_conf_file}
 日志文件：cat /tmp/caddy.log
 使用说明：service caddy start | stop | restart | status
 或者使用：/etc/init.d/caddy start | stop | restart | status
 ${Info_font_prefix}[信息]${Font_suffix} Caddy 安装完成！" && echo
}
uninstall_caddy(){
	check_installed_status
	echo && echo "确定要卸载 Caddy ? [y/N]"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef |grep "caddy" |grep -v "grep" |grep -v "init.d" |grep -v "service" |grep -v "caddy_install" |awk '{print $2}'`
		[[ ! -z ${PID} ]] && kill -9 ${PID}
		if [[ ${release} = "centos" ]]; then
			chkconfig --del caddy
		else
			update-rc.d -f caddy remove
		fi
		[[ -s /tmp/caddy.log ]] && rm -rf /tmp/caddy.log
		rm -rf ${caddy_file}
		rm -rf ${caddy_conf_file}
		rm -rf /etc/init.d/caddy
		[[ ! -e ${caddy_file} ]] && echo && echo -e "${Info_font_prefix}[信息]${Font_suffix} Caddy 卸载完成 !" && echo && exit 1
		echo && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 卸载失败 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
check_sys
action=$1
extension=$2
[[ -z $1 ]] && action=install
case "$action" in
    install|uninstall)
    ${action}_caddy
    ;;
    *)
    echo "输入错误 !"
    echo "用法: {install | uninstall}"
    ;;
esac