#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: dowsDNS
#	Version: 1.0.10
#	Author: Toyo
#	Blog: https://doub.io/dowsdns-jc3/
#=================================================

sh_ver="1.0.10"
file="/usr/local/dowsDNS"
dowsdns_conf="/usr/local/dowsDNS/conf/config.json"
dowsdns_data="/usr/local/dowsDNS/conf/hosts_repository_config.json"
dowsdns_wrcd="/usr/local/dowsDNS/data/wrcd.json"
dowsdns_log="/tmp/dowsdns.log"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}" && Error="${Red_font_prefix}[错误]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"


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
	[[ ! -e ${file} ]] && echo -e "${Error} dowsDNS 没有安装，请检查 !" && exit 1
}
check_pid(){
	PID=`ps -ef| grep "python start.py"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Download_dowsdns(){
	cd "/usr/local"
	#new_ver=$(wget --no-check-certificate -qO- -t1 -T3 https://api.github.com/repos/dowsnature/dowsDNS/releases| grep "tag_name"| head -n 1| awk -F ":" '{print $2}'| sed 's/\"//g;s/,//g;s/ //g;s/v//g')
	#[[ -z "${new_ver}" ]] && echo -e "${Error} dowsDNS 最新版本号获取失败 !" && exit 1
	[[ -e "dowsDNS.zip" ]] && rm -rf "dowsDNS.zip"
	wget --no-check-certificate -O "dowsDNS.zip" "https://github.com/dowsnature/dowsDNS/archive/master.zip"
	[[ ! -e "dowsDNS.zip" ]] && echo -e "${Error} dowsDNS 下载失败 !" && exit 1
	unzip dowsDNS.zip && rm -rf dowsDNS.zip
	[[ ! -e "dowsDNS-master" ]] && echo -e "${Error} dowsDNS 解压失败 !" && exit 1
 	mv dowsDNS-master dowsDNS
 	[[ ! -e "dowsDNS" ]] && echo -e "${Error} dowsDNS 文件夹重命名失败 !" && rm -rf dowsDNS-master && exit 1
}
Service_dowsdns(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/dowsdns_centos" -O /etc/init.d/dowsdns; then
			echo -e "${Error} dowsDNS 服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/dowsdns
		chkconfig --add dowsdns
		chkconfig dowsdns on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/dowsdns_debian" -O /etc/init.d/dowsdns; then
			echo -e "${Error} dowsDNS 服务管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/dowsdns
		update-rc.d -f dowsdns defaults
	fi
	echo -e "${Info} dowsDNS 服务管理脚本下载完成 !"
}
Installation_dependency(){
	python_status=$(python --help)
	if [[ ${release} == "centos" ]]; then
		yum update
		if [[ -z ${python_status} ]]; then
			yum install -y python python-pip unzip
		else
			yum install -y python-pip unzip
		fi
	else
		apt-get update
		if [[ -z ${python_status} ]]; then
			apt-get install -y python python-pip unzip
		else
			apt-get install -y python-pip unzip
		fi
	fi
	pip install requests
}
Write_config(){
	cat > ${dowsdns_conf}<<-EOF
{
	"Remote_dns_server":"${dd_remote_dns_server}",
	"Remote_dns_port":${dd_remote_dns_port},
	"Rpz_json_path":"./data/rpz.json",
	"Local_dns_server":"${dd_local_dns_server}",
	"Local_dns_port":${dd_local_dns_port},
	"sni_proxy_on":${dd_sni_proxy_on},
	"Public_Server":${public_server},
	"sni_proxy_ip":"${dd_sni_proxy_ip}"
}
EOF

}
Read_config(){
	[[ ! -e ${dowsdns_conf} ]] && echo -e "${Error} dowsDNS 配置文件不存在 !" && exit 1
	remote_dns_server=`cat ${dowsdns_conf}|grep "Remote_dns_server"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
	remote_dns_port=`cat ${dowsdns_conf}|grep "Remote_dns_port"|sed -r 's/.*:(.+),.*/\1/'`
	local_dns_server=`cat ${dowsdns_conf}|grep "Local_dns_server"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
	local_dns_port=`cat ${dowsdns_conf}|grep "Local_dns_port"|sed -r 's/.*:(.+),.*/\1/'`
	sni_proxy_ip=`cat ${dowsdns_conf}|grep "sni_proxy_ip"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
}
Read_wrcd(){
	[[ ! -e ${dowsdns_wrcd} ]] && echo -e "${Error} dowsDNS 泛域名解析 配置文件不存在 !" && exit 1
	wrcd_json=$(cat -n ${dowsdns_wrcd}|sed '$d;1d;s/\"//g;s/,//g')
	wrcd_json_num=$(echo -e "${wrcd_json}"|wc -l)
	wrcd_json_num=$(echo $((${wrcd_json_num}+1)))
	echo -e "当前 dowsDNS 泛域名解析配置(不要问我为什么是从 2 开始)：\n"
	echo -e "${wrcd_json}\n"
}
Set_remote_dns_server(){
	echo "请输入 dowsDNS 远程(上游)DNS解析服务器IP"
	read -e -p "(默认: 114.114.114.114):" dd_remote_dns_server
	[[ -z "${dd_remote_dns_server}" ]] && dd_remote_dns_server="114.114.114.114"
	echo
}
Set_remote_dns_port(){
	while true
		do
		echo -e "请输入 dowsDNS 远程(上游)DNS解析服务器端口 [1-65535]"
		read -e -p "(默认: 53):" dd_remote_dns_port
		[[ -z "$dd_remote_dns_port" ]] && dd_remote_dns_port="53"
		echo $((${dd_remote_dns_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${dd_remote_dns_port} -ge 1 ]] && [[ ${dd_remote_dns_port} -le 65535 ]]; then
				echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	done
}
Set_remote_dns(){
	echo -e "请选择并输入 dowsDNS 的远程(上游)DNS解析服务器
 说明：即一些dowsDNS没有指定的域名都由上游DNS解析，比如百度啥的。
 
 ${Green_font_prefix}1.${Font_color_suffix} 114.114.114.114 53
 ${Green_font_prefix}2.${Font_color_suffix} 8.8.8.8 53
 ${Green_font_prefix}3.${Font_color_suffix} 208.67.222.222 53
 ${Green_font_prefix}4.${Font_color_suffix} 208.67.222.222 5353
 ${Green_font_prefix}5.${Font_color_suffix} 自定义输入" && echo
	read -e -p "(默认: 1. 114.114.114.114 53):" dd_remote_dns
	[[ -z "${dd_remote_dns}" ]] && dd_remote_dns="1"
	if [[ ${dd_remote_dns} == "1" ]]; then
		dd_remote_dns_server="114.114.114.114"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "2" ]]; then
		dd_remote_dns_server="8.8.8.8"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "3" ]]; then
		dd_remote_dns_server="208.67.222.222"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "4" ]]; then
		dd_remote_dns_server="208.67.222.222"
		dd_remote_dns_port="5353"
	elif [[ ${dd_remote_dns} == "5" ]]; then
		echo
		Set_remote_dns_server
		Set_remote_dns_port
	else
		dd_remote_dns_server="114.114.114.114"
		dd_remote_dns_port="53"
	fi
	echo && echo "	================================================"
	echo -e "	远程(上游)DNS解析服务器 IP :\t ${Red_background_prefix} ${dd_remote_dns_server} ${Font_color_suffix}
	远程(上游)DNS解析服务器 端口 :\t ${Red_background_prefix} ${dd_remote_dns_port} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_local_dns_server(){
	echo -e "请选择并输入 dowsDNS 的本地监听方式
 ${Green_font_prefix}1.${Font_color_suffix} 127.0.0.1 (只允许本地和局域网设备访问)
 ${Green_font_prefix}2.${Font_color_suffix} 0.0.0.0 (允许外网访问)" && echo
	read -e -p "(默认: 2. 0.0.0.0):" dd_local_dns_server
	[[ -z "${dd_local_dns_server}" ]] && dd_local_dns_server="2"
	if [[ ${dd_local_dns_server} == "1" ]]; then
		dd_local_dns_server="127.0.0.1"
		public_server="false"
	elif [[ ${dd_local_dns_server} == "2" ]]; then
		dd_local_dns_server="0.0.0.0"
		public_server="true"
	else
		dd_local_dns_server="0.0.0.0"
		public_server="true"
	fi
	echo && echo "	================================================"
	echo -e "	本地监听方式: ${Red_background_prefix} ${dd_local_dns_server} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_local_dns_port(){
	while true
		do
		echo -e "请输入 dowsDNS 监听端口 [1-65535]
 注意：大部分设备是不支持设置 非53端口的DNS服务器的，所以非必须请直接回车默认使用 53端口。" && echo
		read -e -p "(默认: 53):" dd_local_dns_port
		[[ -z "$dd_local_dns_port" ]] && dd_local_dns_port="53"
		echo $((${dd_local_dns_port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${dd_local_dns_port} -ge 1 ]] && [[ ${dd_local_dns_port} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	监听端口 : ${Red_background_prefix} ${dd_local_dns_port} ${Font_color_suffix}"
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
Set_sni_proxy_on(){
	echo "是否开启 dowsDNS SNI代理功能？[y/N]
 注意：开启此功能后，任何自定义设置的 hosts或泛域名解析(包括dowsDNS自带的)，都指向设置的SNI代理IP，如果你没有SNI代理IP，请输入 N !"
	read -e -p "(默认: N 关闭):" dd_sni_proxy_on
	[[ -z "${dd_sni_proxy_on}" ]] && dd_sni_proxy_on="n"
	if [[ ${dd_sni_proxy_on} == [Yy] ]]; then
		dd_sni_proxy_on="true"
	else
		dd_sni_proxy_on="false"
	fi
	echo && echo "	================================================"
	echo -e "	SNI代理开关 : ${Red_background_prefix} ${dd_sni_proxy_on} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_sni_proxy_ip(){
	ddd_sni_proxy_ip=$(wget --no-check-certificate -t2 -T4 -qO- "https://raw.githubusercontent.com/dowsnature/dowsDNS/master/conf/config.json"|grep "sni_proxy_ip"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/')
	[[ -z ${ddd_sni_proxy_ip} ]] && ddd_sni_proxy_ip="219.76.4.3"
	echo "请输入 dowsDNS SNI代理 IP（如果没有就直接回车）"
	read -e -p "(默认: ${ddd_sni_proxy_ip}):" dd_sni_proxy_ip
	[[ -z "${dd_sni_proxy_ip}" ]] && dd_sni_proxy_ip="${ddd_sni_proxy_ip}"
	echo && echo "	================================================"
	echo -e "	SNI代理 IP : ${Red_background_prefix} ${dd_sni_proxy_ip} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_conf(){
	Set_remote_dns
	Set_local_dns_server
	Set_local_dns_port
	Set_sni_proxy_on
	Set_sni_proxy_ip
}
Set_dowsdns_basis(){
	check_installed_status
	Set_conf
	Read_config
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_dowsdns
}
Set_wrcd_name(){
	echo "请输入 dowsDNS 要添加/修改的域名(子域名或泛域名)
 注意：假如你想要 youtube.com 及其二级域名全部指向 指定的IP，那么你需要添加 *.youtube.com 和 youtube.com 这两个域名解析才有效。
 这意味着 *.youtube.com 仅代表如 www.youtube.com xxx.youtube.com 这样的二级域名，而不能代表一级域名(顶级域名) youtube.com ！"
	read -e -p "(默认回车取消):" wrcd_name
	[[ -z "${wrcd_name}" ]] && echo "已取消..." && exit 0
	echo
}
Set_wrcd_name_1(){
	echo "检测到当前添加的域名为 泛域名，是否自动添加 上级域名(如顶级域名，就是上面示例说的 youtube.com) [Y/n]"
	read -e -p "(默认: Y 添加):" wrcd_name_1
	[[ -z "${wrcd_name_1}" ]] && wrcd_name_1="y"
	if [[ ${wrcd_name_1} == [Yy] ]]; then
		wrcd_name_1=$(echo -e "${wrcd_name}"|cut -c 3-100)
		echo -e "检测到 上级域名为 : ${Red_font_prefix}${wrcd_name_1}${Font_color_suffix}"
	else
		wrcd_name_1=""
		echo "已取消...继续..."
	fi
	echo
}
Set_wrcd_ip(){
	echo "请输入 dowsDNS 刚才添加/修改的域名要指向的IP
 注意：如果你开启了 SNI代理功能(config.json)，那么你这里设置的自定义泛域名解析都会被 SNI代理功能的SNI代理IP设置所覆盖，也就是统一指向 SNI代理的IP，这里的IP设置就没意义了。"
	read -e -p "(默认回车取消):" wrcd_ip
	[[ -z "${wrcd_ip}" ]] && echo "已取消..." && exit 0
	echo
}
Set_dowsdns_wrcd(){
	check_installed_status
	echo && echo -e "你要做什么？
 ${Green_font_prefix}0.${Font_color_suffix} 查看 泛域名解析列表
 
 ${Green_font_prefix}1.${Font_color_suffix} 添加 泛域名解析
 ${Green_font_prefix}2.${Font_color_suffix} 删除 泛域名解析
 ${Green_font_prefix}3.${Font_color_suffix} 修改 泛域名解析" && echo
	read -e -p "(默认: 取消):" wrcd_modify
	[[ -z "${wrcd_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${wrcd_modify} == "0" ]]; then
		Read_wrcd
	elif [[ ${wrcd_modify} == "1" ]]; then
		Add_wrcd
	elif [[ ${wrcd_modify} == "2" ]]; then
		Del_wrcd
	elif [[ ${wrcd_modify} == "3" ]]; then
		Modify_wrcd
	else
		echo -e "${Error} 请输入正确的数字 [0-3]" && exit 1
	fi
}
Add_wrcd(){
	while true
		do
		Set_wrcd_name
		[[ $(echo -e "${wrcd_name}"|cut -c 1-2) == "*." ]] && Set_wrcd_name_1
		Set_wrcd_ip
		sed -i "2 i \"${wrcd_name}\":\"${wrcd_ip}\"," ${dowsdns_wrcd}
		if [[ $? == "0" ]]; then
			echo -e "${Info} 添加泛域名解析 成功 [${wrcd_name} : ${wrcd_ip}]"
		else
			echo -e "${Error} 添加泛域名解析 失败！" && exit 0
		fi
		if [[ ! -z ${wrcd_name_1} ]]; then
			sed -i "2 i \"${wrcd_name_1}\":\"${wrcd_ip}\"," ${dowsdns_wrcd}
			if [[ $? == "0" ]]; then
				echo -e "${Info} 添加泛域名解析 成功 [${wrcd_name_1} : ${wrcd_ip}]"
			else
				echo -e "${Error} 添加泛域名解析 失败！" && exit 0
			fi
		fi
		echo && echo "是否继续添加 泛域名解析？[Y/n]"
		read -e -p "(默认: Y 继续添加):" wrcd_add_1
		[[ -z "${wrcd_add_1}" ]] && wrcd_add_1="y"
		if [[ ${wrcd_add_1} == [Yy] ]]; then
			continue
		else
			break
		fi
	done
	echo -e "${Info} 重启 dowsDNS中..."
	Restart_dowsdns
}
Del_wrcd(){
	while true
		do
		Read_wrcd
		echo "请根据上面的列表选择你要删除的 泛域名解析 序号数字 [ 2-${wrcd_json_num} ]"
		read -e -p "(默认回车取消):" del_wrcd_num
		[[ -z "$del_wrcd_num" ]] && echo "已取消..." && exit 0
		echo $((${del_wrcd_num}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${del_wrcd_num} -ge 2 ]] && [[ ${del_wrcd_num} -le ${wrcd_json_num} ]]; then
				wrcd_text=$(cat ${dowsdns_wrcd}|sed -n "${del_wrcd_num}p")
				wrcd_name=$(echo -e "${wrcd_text}"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $1}')
				wrcd_ip=$(echo -e "${wrcd_text}"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $2}')
				del_wrcd_determine=$(echo ${wrcd_text:((${#wrcd_text} - 1))})
				if [[ ${del_wrcd_num} == ${wrcd_json_num} ]]; then
					del_wrcd_determine_num=$(echo $((${del_wrcd_num}-1)))
					sed -i "${del_wrcd_determine_num}s/,//g" ${dowsdns_wrcd}
				fi
				sed -i "${del_wrcd_num}d" ${dowsdns_wrcd}
				if [[ $? == "0" ]]; then
					echo -e "${Info} 删除泛域名解析 成功 [${wrcd_name} : ${wrcd_ip}]"
				else
					echo -e "${Error} 删除泛域名解析 失败！" && exit 0
				fi
				echo && echo "是否继续删除 泛域名解析？[Y/n]"
				read -e -p "(默认: Y 继续删除):" wrcd_del_1
				[[ -z "${wrcd_del_1}" ]] && wrcd_del_1="y"
				if [[ ${wrcd_del_1} == [Yy] ]]; then
					continue
				else
					break
				fi
			else
				echo "输入错误, 请输入正确的数字。"
			fi
		else
			echo "输入错误, 请输入正确的数字。"
		fi
	done
	echo -e "${Info} 重启 dowsDNS中..."
	Restart_dowsdns
}
Modify_wrcd(){
	while true
		do
		Read_wrcd
		echo "请根据上面的列表选择你要修改的 泛域名解析 序号数字 [ 2-${wrcd_json_num} ]"
		read -e -p "(默认回车取消):" modify_wrcd_num
		[[ -z "$modify_wrcd_num" ]] && echo "已取消..." && exit 0
		echo $((${modify_wrcd_num}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${modify_wrcd_num} -ge 2 ]] && [[ ${modify_wrcd_num} -le ${wrcd_json_num} ]]; then
				wrcd_name_now=$(cat ${dowsdns_wrcd}|sed -n "${modify_wrcd_num}p"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $1}')
				wrcd_ip_now=$(cat ${dowsdns_wrcd}|sed -n "${modify_wrcd_num}p"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $2}')
				echo
				Set_wrcd_name
				Set_wrcd_ip
				sed -i "${modify_wrcd_num}d" ${dowsdns_wrcd}
				sed -i "${modify_wrcd_num} i \"${wrcd_name}\":\"${wrcd_ip}\"," ${dowsdns_wrcd}
				#sed -i "s/\"${wrcd_name_now_1}\":\"${wrcd_ip_now}\"/\"${wrcd_name_1}\":\"${wrcd_ip}\"/g" ${dowsdns_wrcd}
				if [[ $? == "0" ]]; then
					echo -e "${Info} 修改泛域名解析 成功 [旧 ${wrcd_name_now} : ${wrcd_ip_now} , 新 ${wrcd_name} : ${wrcd_ip}]"
				else
					echo -e "${Error} 修改泛域名解析 失败！" && exit 0
				fi
				break
			else
				echo "输入错误, 请输入正确的数字。"
			fi
		else
			echo "输入错误, 请输入正确的数字。"
		fi
	done
	echo -e "${Info} 重启 dowsDNS中..."
	Restart_dowsdns
}
Install_dowsdns(){
	check_root
	[[ -e ${file} ]] && echo -e "${Error} 检测到 dowsDNS 已安装 !" && exit 1
	check_sys
	echo -e "${Info} 开始设置 用户配置..."
	Set_conf
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装..."
	Download_dowsdns
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_dowsdns
	echo -e "${Info} 开始写入 配置文件..."
	Write_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_dowsdns
}
Start_dowsdns(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} dowsDNS 正在运行，请检查 !" && exit 1
	/etc/init.d/dowsdns start
}
Stop_dowsdns(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} dowsDNS 没有运行，请检查 !" && exit 1
	/etc/init.d/dowsdns stop
}
Restart_dowsdns(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/dowsdns stop
	/etc/init.d/dowsdns start
}
Update_dowsdns(){
	check_installed_status
	check_sys
	cd ${file}
	python update.py
}
Uninstall_dowsdns(){
	check_installed_status
	echo "确定要卸载 dowsDNS ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		Save_iptables
		rm -rf ${file} && rm -rf /etc/init.d/dowsdns
		if [[ ${release} = "centos" ]]; then
			chkconfig --del dowsdns
		else
			update-rc.d -f dowsdns remove
		fi
		echo && echo "dowsDNS 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_dowsdns(){
	check_installed_status
	Read_config
	if [[ ${local_dns_server} == "127.0.0.1" ]]; then
		ip="${local_dns_server} "
	else
		ip=`wget -qO- -t1 -T2 members.3322.org/dyndns/getip`
		[[ -z ${ip} ]] && ip="VPS_IP"
	fi
	clear && echo "————————————————" && echo
	echo -e " 请在你的设备中设置DNS服务器为：
 IP : ${Green_font_prefix}${ip}${Font_color_suffix} ,端口 : ${Green_font_prefix}${local_dns_port}${Font_color_suffix}
 
 注意：如果设备中没有 DNS端口设置选项，那么就只能使用默认的 53 端口"
	echo && echo "————————————————"
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${dd_local_dns_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${dd_local_dns_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${local_dns_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${local_dns_port} -j ACCEPT
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
View_Log(){
	[[ ! -e ${dowsdns_log} ]] && echo -e "${Error} dowsDNS 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${dowsdns_log}${Font_color_suffix} 命令。" && echo
	tail -f ${dowsdns_log}
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/dowsdns.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	if [[ -e "/etc/init.d/dowsdns" ]]; then
		rm -rf /etc/init.d/dowsdns
		Service_dowsdns
	fi
		wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/dowsdns.sh" && chmod +x dowsdns.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
echo && echo -e "  dowsDNS 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/dowsdns-jc3 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 dowsDNS
 ${Green_font_prefix} 2.${Font_color_suffix} 升级 dowsDNS
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 dowsDNS
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 dowsDNS
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 dowsDNS
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 dowsDNS
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 dowsDNS 基础配置
 ${Green_font_prefix} 8.${Font_color_suffix} 设置 dowsDNS 泛域名解析配置
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 dowsDNS 信息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 dowsDNS 日志
————————————" && echo
if [[ -e ${file} ]]; then
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
read -e -p " 请输入数字 [0-9]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_dowsdns
	;;
	2)
	Update_dowsdns
	;;
	3)
	Uninstall_dowsdns
	;;
	4)
	Start_dowsdns
	;;
	5)
	Stop_dowsdns
	;;
	6)
	Restart_dowsdns
	;;
	7)
	Set_dowsdns_basis
	;;
	8)
	Set_dowsdns_wrcd
	;;
	9)
	View_dowsdns
	;;
	10)
	View_Log
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac