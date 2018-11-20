#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: TCP-BBR
#	Version: 1.0.22
#	Author: Toyo
#	Blog: https://doub.io/wlzy-16/
#=================================================

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')

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
}
Set_latest_new_version(){
	echo -e "请输入 要下载安装的Linux内核版本(BBR) ${Green_font_prefix}[ 格式: x.xx.xx ，例如: 4.9.96 ]${Font_color_suffix}
${Tip} 内核版本列表请去这里获取：${Green_font_prefix}[ http://kernel.ubuntu.com/~kernel-ppa/mainline/ ]${Font_color_suffix}
建议使用${Green_font_prefix}稳定版本：4.9.XX ${Font_color_suffix}，4.9 以上版本属于测试版，稳定版与测试版同步更新，BBR 加速效果无区别。"
	read -e -p "(直接回车，自动获取最新稳定版本):" latest_version
	[[ -z "${latest_version}" ]] && get_latest_new_version
	echo
}
# 本段获取最新版本的代码来源自: https://teddysun.com/489.html
get_latest_new_version(){
	echo -e "${Info} 检测稳定版内核最新版本中..."
	latest_version=$(wget -qO- -t1 -T2 "http://kernel.ubuntu.com/~kernel-ppa/mainline/" | awk -F'\"v' '/v4.9.*/{print $2}' |grep -v '\-rc'| cut -d/ -f1 | sort -V | tail -1)
	[[ -z ${latest_version} ]] && echo -e "${Error} 检测内核最新版本失败 !" && exit 1
	echo -e "${Info} 稳定版内核最新版本为 : ${latest_version}"
}
get_latest_version(){
	Set_latest_new_version
	bit=`uname -m`
	if [[ ${bit} == "x86_64" ]]; then
		deb_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "generic" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1 )
		deb_kernel_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${deb_name}"
		deb_kernel_name="linux-image-${latest_version}-amd64.deb"
	else
		deb_name=$(wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/ | grep "linux-image" | grep "generic" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1)
		deb_kernel_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${latest_version}/${deb_name}"
		deb_kernel_name="linux-image-${latest_version}-i386.deb"
	fi
}
#检查内核是否满足
check_deb_off(){
	get_latest_new_version
	deb_ver=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	latest_version_2=$(echo "${latest_version}"|grep -o '\.'|wc -l)
	if [[ "${latest_version_2}" == "1" ]]; then
		latest_version="${latest_version}.0"
	fi
	if [[ "${deb_ver}" != "" ]]; then
		if [[ "${deb_ver}" == "${latest_version}" ]]; then
			echo -e "${Info} 检测到当前内核版本[${deb_ver}] 已满足要求，继续..."
		else
			echo -e "${Tip} 检测到当前内核版本[${deb_ver}] 支持开启BBR 但不是最新内核版本，可以使用${Green_font_prefix} bash ${file}/bbr.sh ${Font_color_suffix}来升级内核 !(注意：并不是越新的内核越好，4.9 以上版本的内核 目前皆为测试版，不保证稳定性，旧版本如使用无问题 建议不要升级！)"
		fi
	else
		echo -e "${Error} 检测到当前内核版本[${deb_ver}] 不支持开启BBR，请使用${Green_font_prefix} bash ${file}/bbr.sh ${Font_color_suffix}来更换最新内核 !" && exit 1
	fi
}
# 删除其余内核
del_deb(){
	deb_total=`dpkg -l | grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
	if [[ "${deb_total}" -ge "1" ]]; then
		echo -e "${Info} 检测到 ${deb_total} 个其余内核，开始卸载..."
		for((integer = 1; integer <= ${deb_total}; integer++))
		do
			deb_del=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | head -${integer}`
			echo -e "${Info} 开始卸载 ${deb_del} 内核..."
			apt-get purge -y ${deb_del}
			echo -e "${Info} 卸载 ${deb_del} 内核卸载完成，继续..."
		done
		deb_total=`dpkg -l|grep linux-image | awk '{print $2}' | wc -l`
		if [[ "${deb_total}" = "1" ]]; then
			echo -e "${Info} 内核卸载完毕，继续..."
		else
			echo -e "${Error} 内核卸载异常，请检查 !" && exit 1
		fi
	else
		echo -e "${Info} 检测到除刚安装的内核以外已无多余内核，跳过卸载多余内核步骤 !"
	fi
}
del_deb_over(){
	del_deb
	update-grub
	addsysctl
	echo -e "${Tip} 重启VPS后，请运行脚本查看 BBR 是否正常加载，运行命令： ${Green_background_prefix} bash ${file}/bbr.sh status ${Font_color_suffix}"
	read -e -p "需要重启VPS后，才能开启BBR，是否现在重启 ? [Y/n] :" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
}
# 安装BBR
installbbr(){
	check_root
	get_latest_version
	deb_ver=`dpkg -l|grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep '[4-9].[0-9]*.'`
	latest_version_2=$(echo "${latest_version}"|grep -o '\.'|wc -l)
	if [[ "${latest_version_2}" == "1" ]]; then
		latest_version="${latest_version}.0"
	fi
	if [[ "${deb_ver}" != "" ]]; then	
		if [[ "${deb_ver}" == "${latest_version}" ]]; then
			echo -e "${Info} 检测到当前内核版本[${deb_ver}] 已是最新版本，无需继续 !"
			deb_total=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${latest_version}" | wc -l`
			if [[ "${deb_total}" != "0" ]]; then
				echo -e "${Info} 检测到内核数量异常，存在多余内核，开始删除..."
				del_deb_over
			else
				exit 1
			fi
		else
			echo -e "${Info} 检测到当前内核版本支持开启BBR 但不是最新内核版本，开始升级(或降级)内核..."
		fi
	else
		echo -e "${Info} 检测到当前内核版本不支持开启BBR，开始..."
		virt=`virt-what`
		if [[ -z ${virt} ]]; then
			apt-get update && apt-get install virt-what -y
			virt=`virt-what`
		fi
		if [[ ${virt} == "openvz" ]]; then
			echo -e "${Error} BBR 不支持 OpenVZ 虚拟化(不支持更换内核) !" && exit 1
		fi
	fi
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	
	wget -O "${deb_kernel_name}" "${deb_kernel_url}"
	if [[ -s ${deb_kernel_name} ]]; then
		echo -e "${Info} 内核安装包下载成功，开始安装内核..."
		dpkg -i ${deb_kernel_name}
		rm -rf ${deb_kernel_name}
	else
		echo -e "${Error} 内核安装包下载失败，请检查 !" && exit 1
	fi
	#判断内核是否安装成功
	deb_ver=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${latest_version}"`
	if [[ "${deb_ver}" != "" ]]; then
		echo -e "${Info} 检测到内核安装成功，开始卸载其余内核..."
		del_deb_over
	else
		echo -e "${Error} 检测到内核安装失败，请检查 !" && exit 1
	fi
}
bbrstatus(){
	check_bbr_status_on=`sysctl net.ipv4.tcp_congestion_control | awk '{print $3}'`
	if [[ "${check_bbr_status_on}" = "bbr" ]]; then
		echo -e "${Info} 检测到 BBR 已开启 !"
		# 检查是否启动BBR
		check_bbr_status_off=`lsmod | grep bbr`
		if [[ "${check_bbr_status_off}" = "" ]]; then
			echo -e "${Error} 检测到 BBR 已开启但未正常启动，请尝试使用低版本内核(可能是存着兼容性问题，虽然内核配置中打开了BBR，但是内核加载BBR模块失败) !"
		else
			echo -e "${Info} 检测到 BBR 已开启并已正常启动 !"
		fi
		exit 1
	fi
}
addsysctl(){
	sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
	
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sysctl -p
}
startbbr(){
	check_deb_off
	bbrstatus
	addsysctl
	sleep 1s
	bbrstatus
}
# 关闭BBR
stopbbr(){
	check_deb_off
	sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
	sysctl -p
	sleep 1s
	
	read -e -p "需要重启VPS后，才能彻底停止BBR，是否现在重启 ? [Y/n] :" yn
	[[ -z "${yn}" ]] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} VPS 重启中..."
		reboot
	fi
}
# 查看BBR状态
statusbbr(){
	check_deb_off
	bbrstatus
	echo -e "${Error} BBR 未开启 !"
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|start|stop|status)
	${action}bbr
	;;
	*)
	echo "输入错误 !"
	echo "用法: { install | start | stop | status }"
	;;
esac