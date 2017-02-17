#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6/Debian/Ubuntu 14.04+
#	Description: Install the ShadowsocksR server
#	Version: 1.2.5
#	Author: Toyo
#	Blog: https://doub.io/ss-jc42/
#=================================================

#ssr_pid="/var/run/shadowsocks.pid"
ssr_file="/etc/shadowsocksr"
ssr_ss_file="/etc/shadowsocksr/shadowsocks/"
config_file="/etc/shadowsocksr/config.json"
config_user_file="/etc/shadowsocksr/user-config.json"
Libsodiumr_file="/root/libsodium"
Libsodiumr_ver="1.0.11"
auto_restart_cron="auto_restart_cron.sh"
Separator_1="——————————————————————————————"

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
	#bit=`uname -m`
}
SSR_install_status(){
	[[ ! -e $config_user_file ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
}
#获取IP
getIP(){
	ip=`curl -m 10 -s "ipinfo.io" | jq '.ip' | sed 's/^.//;s/.$//'`
	[[ -z "$ip" ]] && ip="VPS_IP"
}
#获取用户账号信息
getUser(){
	port=`jq '.server_port' ${config_user_file}`
	password=`jq '.password' ${config_user_file} | sed 's/^.//;s/.$//'`
	method=`jq '.method' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol=`jq '.protocol' ${config_user_file} | sed 's/^.//;s/.$//'`
	obfs=`jq '.obfs' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol_param=`jq '.protocol_param' ${config_user_file} | sed 's/^.//;s/.$//'`
	speed_limit_per_con=`jq '.speed_limit_per_con' ${config_user_file}`
	speed_limit_per_user=`jq '.speed_limit_per_user' ${config_user_file}`
}
# 设置 端口和密码
set_port_pass(){
	#设置端口
	while true
	do
	echo -e "请输入ShadowsocksR账号的 端口 [1-65535]:"
	read -p "(默认端口: 2333):" ssport
	[[ -z "$ssport" ]] && ssport="2333"
	expr ${ssport} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssport} -ge 1 ]] && [[ ${ssport} -le 65535 ]]; then
			echo && echo ${Separator_1} && echo -e "	端口 : \033[32m${ssport}\033[0m" && echo ${Separator_1} && echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
	#设置密码
	echo "请输入ShadowsocksR账号的 密码:"
	read -p "(默认密码: doub.io):" sspwd
	[[ -z "${sspwd}" ]] && sspwd="doub.io"
	echo && echo ${Separator_1} && echo -e "	密码 : \033[32m${sspwd}\033[0m" && echo ${Separator_1} && echo
}
# 设置 加密方式、协议和混淆等
set_others(){
	#设置加密方式
	echo "请输入数字 来选择ShadowsocksR账号的 加密方式:"
	echo " 1. rc4-md5"
	echo " 2. aes-128-ctr"
	echo " 3. aes-256-ctr"
	echo " 4. aes-256-cfb"
	echo " 5. aes-256-cfb8"
	echo " 6. camellia-256-cfb"
	echo " 7. chacha20"
	echo " 8. chacha20-ietf"
	echo -e "\033[32m 注意: \033[0mchacha20*等加密方式 需要安装 libsodium 支持库，否则会启动失败！"
	echo
	read -p "(默认加密方式: 2. aes-128-ctr):" ssmethod
	[[ -z "${ssmethod}" ]] && ssmethod="2"
	if [[ ${ssmethod} == "1" ]]; then
		ssmethod="rc4-md5"
	elif [[ ${ssmethod} == "2" ]]; then
		ssmethod="aes-128-ctr"
	elif [[ ${ssmethod} == "3" ]]; then
		ssmethod="aes-256-ctr"
	elif [[ ${ssmethod} == "4" ]]; then
		ssmethod="aes-256-cfb"
	elif [[ ${ssmethod} == "5" ]]; then
		ssmethod="aes-256-cfb8"
	elif [[ ${ssmethod} == "6" ]]; then
		ssmethod="camellia-256-cfb"
	elif [[ ${ssmethod} == "7" ]]; then
		ssmethod="chacha20"
	elif [[ ${ssmethod} == "8" ]]; then
		ssmethod="chacha20-ietf"
	else
		ssmethod="aes-128-ctr"
	fi
	echo && echo ${Separator_1} && echo -e "	加密方式 : \033[32m${ssmethod}\033[0m" && echo ${Separator_1} && echo
	#设置协议
	echo "请输入数字 来选择ShadowsocksR账号的 协议( auth_aes128_* 以后的协议不再支持 兼容原版 ):"
	echo " 1. origin"
	echo " 2. auth_sha1_v4"
	echo " 3. auth_aes128_md5"
	echo " 4. auth_aes128_sha1"
	echo
	read -p "(默认协议: 2. auth_sha1_v4):" ssprotocol
	[[ -z "${ssprotocol}" ]] && ssprotocol="2"
	if [[ ${ssprotocol} == "1" ]]; then
		ssprotocol="origin"
	elif [[ ${ssprotocol} == "2" ]]; then
		ssprotocol="auth_sha1_v4"
	elif [[ ${ssprotocol} == "3" ]]; then
		ssprotocol="auth_aes128_md5"
	elif [[ ${ssprotocol} == "4" ]]; then
		ssprotocol="auth_aes128_sha1"
	else
		ssprotocol="auth_sha1_v4"
	fi
	echo && echo ${Separator_1} && echo -e "	协议 : \033[32m${ssprotocol}\033[0m" && echo ${Separator_1} && echo
	#设置混淆
	echo "请输入数字 来选择ShadowsocksR账号的 混淆:"
	echo " 1. plain"
	echo " 2. http_simple"
	echo " 3. http_post"
	echo " 4. random_head"
	echo " 5. tls1.2_ticket_auth"
	echo
	read -p "(默认混淆: 5. tls1.2_ticket_auth):" ssobfs
	[[ -z "${ssobfs}" ]] && ssobfs="5"
	if [[ ${ssobfs} == "1" ]]; then
		ssobfs="plain"
	elif [[ ${ssobfs} == "2" ]]; then
		ssobfs="http_simple"
	elif [[ ${ssobfs} == "3" ]]; then
		ssobfs="http_post"
	elif [[ ${ssobfs} == "4" ]]; then
		ssobfs="random_head"
	elif [[ ${ssobfs} == "5" ]]; then
		ssobfs="tls1.2_ticket_auth"
	else
		ssobfs="tls1.2_ticket_auth"
	fi
	echo && echo ${Separator_1} && echo -e "	混淆 : \033[32m${ssobfs}\033[0m" && echo ${Separator_1} && echo
	#询问是否设置 混淆 兼容原版
	if [[ ${ssprotocol} != "origin" ]]; then
		if [[ ${ssobfs} != "plain" ]]; then
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				read -p "是否设置 协议/混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
				[[ -z "${yn1}" ]] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible" && ssprotocol=${ssprotocol}"_compatible"
			else
				read -p "是否设置 混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
				[[ -z "${yn1}" ]] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
			fi
		else
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				read -p "是否设置 协议 兼容原版 ( _compatible )? [Y/n] :" yn1
				[[ -z "${yn1}" ]] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssprotocol=${ssprotocol}"_compatible"
			fi
		fi
	else
		if [[ ${ssobfs} != "plain" ]]; then
			read -p "是否设置 混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
			[[ -z "${yn1}" ]] && yn1="y"
			[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
		fi
	fi
	if [[ ${ssprotocol} != "origin" ]]; then
		while true
		do
		echo
		echo -e "请输入 ShadowsocksR账号欲限制的设备数 (\033[32m auth_* 系列协议 不兼容原版才有效 \033[0m)"
		echo -e "\033[32m 注意: \033[0m该设备数限制，指的是每个端口同一时间能链接的客户端数量(多端口模式，每个端口都是独立计算)。"
		read -p "(回车 默认无限):" ssprotocol_param
		[[ -z "$ssprotocol_param" ]] && ssprotocol_param="" && break
		expr ${ssprotocol_param} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${ssprotocol_param} -ge 1 ]] && [[ ${ssprotocol_param} -le 99999 ]]; then
				echo && echo ${Separator_1} && echo -e "	设备数 : \033[32m${ssprotocol_param}\033[0m" && echo ${Separator_1} && echo
				break
			else
				echo "输入错误，请输入正确的数字 !"
			fi
		else
			echo "输入错误，请输入正确的数字 !"
		fi
		done
	fi
	# 设置单线程限速
	while true
	do
	echo
	echo -e "请输入 你要设置的每个端口 单线程 限速上限(单位：KB/S)"
	echo -e "\033[32m 注意: \033[0m这个指的是，每个端口 单线程的限速上限，多线程即无效。"
	read -p "(回车 默认无限):" ssspeed_limit_per_con
	[[ -z "$ssspeed_limit_per_con" ]] && ssspeed_limit_per_con=0 && break
	expr ${ssspeed_limit_per_con} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_con} -ge 1 ]] && [[ ${ssspeed_limit_per_con} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	单端口单线程 : \033[32m${ssspeed_limit_per_con} KB/S\033[0m" && echo ${Separator_1} && echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
	# 设置端口总限速
	while true
	do
	echo
	echo -e "请输入 你要设置的每个端口 总速度 限速上限(单位：KB/S)"
	echo -e "\033[32m 注意: \033[0m这个指的是，每个端口 总速度 限速上限，单个端口整体限速。"
	read -p "(回车 默认无限):" ssspeed_limit_per_user
	[[ -z "$ssspeed_limit_per_user" ]] && ssspeed_limit_per_user=0 && break
	expr ${ssspeed_limit_per_user} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_user} -ge 1 ]] && [[ ${ssspeed_limit_per_user} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	单端口总限速 : \033[32m${ssspeed_limit_per_user} KB/S\033[0m" && echo ${Separator_1} && echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
}
#设置用户账号信息
setUser(){
	set_port_pass
	set_others
	#最后确认
	[[ "${ssprotocol_param}" == "" ]] && ssprotocol_param="0(无限)"
	echo && echo ${Separator_1}
	echo " 请检查Shadowsocks账号配置是否有误 !" && echo
	echo -e " 端口\t    : \033[32m${ssport}\033[0m"
	echo -e " 密码\t    : \033[32m${sspwd}\033[0m"
	echo -e " 加密\t    : \033[32m${ssmethod}\033[0m"
	echo -e " 协议\t    : \033[32m${ssprotocol}\033[0m"
	echo -e " 混淆\t    : \033[32m${ssobfs} \033[0m"
	echo -e " 设备数限制 : \033[32m${ssprotocol_param}\033[0m"
	echo -e " 单线程限速 : \033[32m${ssspeed_limit_per_con} KB/S\033[0m"
	echo -e " 端口总限速 : \033[32m${ssspeed_limit_per_user} KB/S\033[0m"
	echo ${Separator_1} && echo
	read -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	[[ "${ssprotocol_param}" = "0(无限)" ]] && ssprotocol_param=""
}
ss_link_qr(){
	SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	SSurl="ss://"${SSbase64}
	SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
	ss_link=" SS    链接 : \033[32m${SSurl}\033[0m \n SS  二维码 : \033[32m${SSQRcode}\033[0m"
}
ssr_link_qr(){
	SSRprotocol=`echo ${protocol} | sed 's/_compatible//g'`
	SSRobfs=`echo ${obfs} | sed 's/_compatible//g'`
	SSRPWDbase64=`echo -n "${password}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	SSRbase64=`echo -n "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	SSRurl="ssr://"${SSRbase64}
	SSRQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSRurl}
	ssr_link=" SSR   链接 : \033[32m${SSRurl}\033[0m \n SSR 二维码 : \033[32m${SSRQRcode}\033[0m \n "
}
#显示用户账号信息
viewUser(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ -z "${PID}" ]]; then
		ssr_status="\033[41;37m 当前状态: \033[0m ShadowsocksR 没有运行！"
	else
		ssr_status="\033[42;37m 当前状态: \033[0m ShadowsocksR 正在运行！"
	fi
	getIP
	now_mode=`jq '.port_password' ${config_user_file}`
	if [[ "${now_mode}" = "null" ]]; then
		getUser
		SSprotocol=`echo ${protocol} | awk -F "_" '{print $NF}'`
		SSobfs=`echo ${obfs} | awk -F "_" '{print $NF}'`
		if [[ ${protocol} = "origin" ]]; then
			if [[ ${obfs} = "plain" ]]; then
				ss_link_qr
				ssr_link=""
			else
				if [[ ${SSobfs} != "compatible" ]]; then
					ss_link=""
				else
					ss_link_qr
				fi
			fi
		else
			if [[ ${SSprotocol} != "compatible" ]]; then
				ss_link=""
			else
				if [[ ${SSobfs} != "compatible" ]]; then
					if [[ ${SSobfs} = "plain" ]]; then
						ss_link_qr
					else
						ss_link=""
					fi
				else
					ss_link_qr
				fi
			fi
		fi
		ssr_link_qr
		[[ -z ${protocol_param} ]] && protocol_param="0(无限)"
		clear
		echo "==================================================="
		echo
		echo -e " 你的ShadowsocksR 账号配置 : "
		echo
		echo -e " I  P\t    : \033[32m${ip}\033[0m"
		echo -e " 端口\t    : \033[32m${port}\033[0m"
		echo -e " 密码\t    : \033[32m${password}\033[0m"
		echo -e " 加密\t    : \033[32m${method}\033[0m"
		echo -e " 协议\t    : \033[32m${protocol}\033[0m"
		echo -e " 混淆\t    : \033[32m${obfs}\033[0m"
		echo -e " 设备数限制 : \033[32m${protocol_param}\033[0m"
		echo -e " 单线程限速 : \033[32m${speed_limit_per_con} KB/S\033[0m"
		echo -e " 端口总限速 : \033[32m${speed_limit_per_user} KB/S\033[0m"
		echo -e "${ss_link}"
		echo -e "${ssr_link}"
		echo -e "\033[42;37m 提示: \033[0m"
		echo -e " 浏览器中，打开二维码链接，就可以看到二维码图片。"
		echo -e " 协议和混淆后面的[ _compatible ]，指的是兼容原版Shadowsocks协议/混淆。"
		echo
		echo -e ${ssr_status}
		echo
		echo "==================================================="
	else
		getUser
		[[ -z ${protocol_param} ]] && protocol_param="0(无限)"
		clear
		echo "==================================================="
		echo
		echo -e " 你的ShadowsocksR 账号配置 : "
		echo
		echo -e " I  P\t    : \033[32m${ip}\033[0m"
		echo -e " 加密\t    : \033[32m${method}\033[0m"
		echo -e " 协议\t    : \033[32m${protocol}\033[0m"
		echo -e " 混淆\t    : \033[32m${obfs}\033[0m"
		echo -e " 设备数限制 : \033[32m${protocol_param}\033[0m"
		echo -e " 单线程限速 : \033[32m${speed_limit_per_con} KB/S\033[0m"
		echo -e " 端口总限速 : \033[32m${speed_limit_per_user} KB/S\033[0m"
		echo
		user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		[[ ${socat_total} = "0" ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现 多端口用户，请检查 !" && exit 1
		user_id=0
		check_sys
		if [[ ${release} = "centos" ]]; then
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_id=$[$user_id+1]	
			
				SSprotocol=`echo ${protocol} | awk -F "_" '{print $NF}'`
				SSobfs=`echo ${obfs} | awk -F "_" '{print $NF}'`
				if [[ ${protocol} = "origin" ]]; then
					if [[ ${obfs} = "plain" ]]; then
						ss_link_qr
						ssr_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							ss_link=""
						else
							ss_link_qr
						fi
					fi
				else
					if [[ ${SSprotocol} != "compatible" ]]; then
						ss_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							if [[ ${SSobfs} = "plain" ]]; then
								ss_link_qr
							else
								ss_link=""
							fi
						else
							ss_link_qr
						fi
					fi
				fi
				ssr_link_qr
				echo -e " ——————————\033[42;37m 用户 ${user_id} \033[0m ——————————"
				echo -e " 端口\t    : \033[32m${user_port}\033[0m"
				echo -e " 密码\t    : \033[32m${user_password}\033[0m"
				echo -e "${ss_link}"
				echo -e "${ssr_link}"
			done
		else
			for((integer = ${user_total}; integer >= 1; integer--))
			do
				user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_id=$[$user_id+1]	
			
				SSprotocol=`echo ${protocol} | awk -F "_" '{print $NF}'`
				SSobfs=`echo ${obfs} | awk -F "_" '{print $NF}'`
				if [[ ${protocol} = "origin" ]]; then
					if [[ ${obfs} = "plain" ]]; then
						ss_link_qr
						ssr_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							ss_link=""
						else
							ss_link_qr
						fi
					fi
				else
					if [[ ${SSprotocol} != "compatible" ]]; then
						ss_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							if [[ ${SSobfs} = "plain" ]]; then
								ss_link_qr
							else
								ss_link=""
							fi
						else
							ss_link_qr
						fi
					fi
				fi
				ssr_link_qr
				echo -e " —————————— \033[42;37m 用户 ${user_id} \033[0m ——————————"
				echo -e " 端口\t    : \033[32m${user_port}\033[0m"
				echo -e " 密码\t    : \033[32m${user_password}\033[0m"
				echo -e "${ss_link}"
				echo -e "${ssr_link}"
			done
		fi
		echo -e "\033[42;37m 提示: \033[0m"
		echo -e " 浏览器中，打开二维码链接，就可以看到二维码图片。"
		echo -e " 协议和混淆后面的[ _compatible ]，指的是兼容原版Shadowsocks协议/混淆。"
		echo
		echo -e ${ssr_status}
		echo
		echo "==================================================="
	fi
	
}
debian_apt(){
	apt-get update
	apt-get install -y python-pip python-m2crypto curl unzip vim git gcc build-essential make
}
centos_yum(){
	yum update
	yum install -y python-pip python-m2crypto curl unzip vim git gcc make
}
JQ_install(){
	JQ_ver=`jq -V`
	if [[ -z ${JQ_ver} ]]; then
		#wget --no-check-certificate -N "https://softs.pw/Bash/other/jq-1.5.tar.gz"
		wget --no-check-certificate -N "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/jq-1.5.tar.gz"
		tar -xzf jq-1.5.tar.gz && cd jq-1.5
		./configure --disable-maintainer-mode && make && make install
		ldconfig
		cd .. && rm -rf jq-1.5.tar.gz && rm -rf jq-1.5
		JQ_ver=`jq -V`
		[[ -z ${JQ_ver} ]]&& echo -e "\033[41;37m [错误] \033[0m JSON解析器 JQ 安装失败 !" && exit 1
		echo -e "\033[42;37m [信息] \033[0m JSON解析器 JQ 安装完成，继续..." 
	else
		echo -e "\033[42;37m [信息] \033[0m 检测到 JSON解析器 JQ 已安装，继续..."
	fi
}
rc.local_ss_set(){
#添加开机启动
	if [[ ${release} = "centos" ]]; then
		chmod +x /etc/rc.d/rc.local
		sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.d/rc.local
		sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.d/rc.local
		echo -e "cd ${ssr_ss_file}" >> /etc/rc.d/rc.local
		echo -e "nohup python server.py a >> ssserver.log 2>&1 &" >> /etc/rc.d/rc.local
	else
		chmod +x /etc/rc.local
		sed -i '$d' /etc/rc.local
		sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.local
		sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.local
		echo -e "cd ${ssr_ss_file}" >> /etc/rc.local
		echo -e "nohup python server.py a >> ssserver.log 2>&1 &" >> /etc/rc.local
		echo -e "exit 0" >> /etc/rc.local
	fi
}
rc.local_ss_del(){
	if [[ ${release} = "centos" ]]; then
		sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.d/rc.local
		sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.d/rc.local
	else
		sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.local
		sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.local
	fi
}
rc.local_serverspeed_set(){
#添加开机启动
	if [[ ${release} = "centos" ]]; then
		chmod +x /etc/rc.d/rc.local
		sed -i '/\/serverspeeder\/bin\/serverSpeeder.sh start/d' /etc/rc.d/rc.local
		echo -e "/serverspeeder/bin/serverSpeeder.sh start" >> /etc/rc.d/rc.local
	else
		chmod +x /etc/rc.local
		sed -i '$d' /etc/rc.local
		sed -i '/\/serverspeeder\/bin\/serverSpeeder.sh start/d' /etc/rc.local
		echo -e "/serverspeeder/bin/serverSpeeder.sh start" >> /etc/rc.local
		echo -e "exit 0" >> /etc/rc.local
	fi
}
rc.local_serverspeed_del(){
	if [[ ${release} = "centos" ]]; then
		sed -i '/\/serverspeeder\/bin\/serverSpeeder.sh start/d' /etc/rc.d/rc.local
	else
		sed -i '/\/serverspeeder\/bin\/serverSpeeder.sh start/d' /etc/rc.local
	fi
}
iptables_add(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssport} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssport} -j ACCEPT
}
iptables_del(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
iptables_set(){
	#删除旧端口的防火墙规则，添加新端口的规则
	iptables_del
	iptables_add
}
set_config_port_pass(){
	sed -i 's/"server_port": '$(echo ${port})'/"server_port": '$(echo ${ssport})'/g' ${config_user_file}
	sed -i 's/"password": "'$(echo ${password})'"/"password": "'$(echo ${sspwd})'"/g' ${config_user_file}
}
set_config_method_obfs_protocol(){
	sed -i 's/"method": "'$(echo ${method})'"/"method": "'$(echo ${ssmethod})'"/g' ${config_user_file}
	sed -i 's/"obfs": "'$(echo ${obfs})'"/"obfs": "'$(echo ${ssobfs})'"/g' ${config_user_file}
	sed -i 's/"protocol": "'$(echo ${protocol})'"/"protocol": "'$(echo ${ssprotocol})'"/g' ${config_user_file}
}
set_config_protocol_param(){
	sed -i 's/"protocol_param": "'$(echo ${protocol_param})'"/"protocol_param": "'$(echo ${ssprotocol_param})'"/g' ${config_user_file}
}
set_config_speed_limit_per(){
	sed -i 's/"speed_limit_per_con": '$(echo ${speed_limit_per_con})'/"speed_limit_per_con": '$(echo ${ssspeed_limit_per_con})'/g' ${config_user_file}
	sed -i 's/"speed_limit_per_user": '$(echo ${speed_limit_per_user})'/"speed_limit_per_user": '$(echo ${ssspeed_limit_per_user})'/g' ${config_user_file}
}
#安装ShadowsocksR
installSSR(){
	[[ -e $config_user_file ]] && echo -e "\033[41;37m [错误] \033[0m 发现已安装ShadowsocksR，如果需要继续安装，请先卸载 !" && exit 1
	setUser
	check_sys
	# 系统判断
	if [[ ${release} = "debian" ]]; then
		debian_apt
	elif [[ ${release} = "ubuntu" ]]; then
		debian_apt
	elif [[ ${release} = "centos" ]]; then
		centos_yum
	else
		echo -e "\033[41;37m [错误] \033[0m 本脚本不支持当前系统 !" && exit 1
	fi
	#修改DNS为8.8.8.8
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	JQ_install
	cd /etc
	#git config --global http.sslVerify false
	env GIT_SSL_NO_VERIFY=true git clone -b manyuser https://github.com/shadowsocksr/shadowsocksr.git
	[[ ! -e ${config_file} ]] && echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 下载失败 !" && exit 1
	cp ${config_file} ${config_user_file}
	#修改配置文件的密码 端口 加密方式
	cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": ${ssport},
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "${sspwd}",
    "timeout": 120,
    "udp_timeout": 60,
    "method": "${ssmethod}",
    "protocol": "${ssprotocol}",
    "protocol_param": "${ssprotocol_param}",
    "obfs": "${ssobfs}",
    "obfs_param": "",
    "speed_limit_per_con": ${ssspeed_limit_per_con},
    "speed_limit_per_user": ${ssspeed_limit_per_user},
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF

	#添加新端口的规则
	iptables_add
	rc.local_ss_set
	#启动SSR服务端，并判断是否启动成功
	cd ${ssr_ss_file}
	nohup python server.py a >> ssserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ ! -z "${PID}" ]]; then
		viewUser
		echo
		echo -e "ShadowsocksR 安装完成 !"
		echo -e "https://doub.io/ss-jc42/"
		echo
		echo "############################################################"
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR服务端启动失败 !"
	fi
}
installLibsodium(){
	# 系统判断
	check_sys
	if [[ ${release}  != "debian" ]]; then
		if [[ ${release}  != "ubuntu" ]]; then
			if [[ ${release}  != "centos" ]]; then
				echo -e "\033[41;37m [错误] \033[0m 本脚本不支持当前系统 !" && exit 1
			fi
		fi
	fi
	if [[ ${release} != "centos" ]]; then
		apt-get update && apt-get install -y gcc build-essential make
		cd /root
		wget  --no-check-certificate -O libsodium.tar.gz https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz
		tar -xzf libsodium.tar.gz && mv libsodium-${Libsodiumr_ver} libsodium && cd libsodium
		./configure --disable-maintainer-mode && make -j2 && make install
		ldconfig
		cd .. && rm -rf libsodium.tar.gz && rm -rf libsodium
	else
		yum update && yum install epel-release -y && yum install libsodium -y
	fi
	echo ${Separator_1} && echo
	echo -e "Libsodium 安装完成 !"
	echo -e "https://doub.io/ss-jc42/"
	echo && echo ${Separator_1}
}
#修改单端口用户配置
modifyUser(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" != "null" ]] && echo -e "\033[41;37m [错误] \033[0m 当前ShadowsocksR模式为 多端口，请检查 !" && exit 1
	getUser
	setUser
	#修改配置文件的密码 端口 加密方式
	set_config_port_pass
	set_config_method_obfs_protocol
	set_config_protocol_param
	set_config_speed_limit_per
	iptables_set
	RestartSSR
}
#手动修改用户配置
manuallyModifyUser(){
	SSR_install_status
	port=`jq '.server_port' ${config_user_file}`
	vi $config_user_file
	ssport=`jq '.server_port' ${config_user_file}`
	iptables_set
	RestartSSR
}
#卸载ShadowsocksR
UninstallSSR(){
	[[ ! -e $config_file ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	echo "确定要卸载ShadowsocksR ? (y/N)"
	echo
	read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
#停止ShadowsocksR服务端并删除防火墙规则，删除Shadowsocks文件夹。
		PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
		[[ ! -z "${PID}" ]] && kill -9 ${PID}
		cron_ssr=`crontab -l | grep "${ssr_file}/${auto_restart_cron}" | wc -l`
		if [[ ${cron_ssr} > "0" ]]; then
			crontab -l > ${ssr_file}"/crontab.bak"
			sed -i "/\/etc\/shadowsocksr\/${auto_restart_cron}/d" ${ssr_file}"/crontab.bak"
			crontab ${ssr_file}"/crontab.bak"
			rm -rf ${ssr_file}"/crontab.bak"
		fi
		now_mode=`jq '.port_password' ${config_user_file}`
		if [[ "${now_mode}" = "null" ]]; then
			port=`jq '.server_port' ${config_user_file}`
			iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		else
			user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				iptables_del
			done
		fi
#取消开机启动
		check_sys
		rc.local_ss_del
		rm -rf ${ssr_file} && rm -rf ${Libsodiumr_file} && rm -rf ${Libsodiumr_file}.tar.gz
		echo && echo "	ShadowsocksR 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
# 更新ShadowsocksR
UpdateSSR(){
	SSR_install_status
	cd ${ssr_file}
	git pull
	RestartSSR
}
# 切换 单/多端口模式
Port_mode_switching(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	if [[ "${now_mode}" = "null" ]]; then
		echo
		echo -e "	当前ShadowsocksR模式：\033[42;37m 单端口 \033[0m"
		echo
		echo -e "确定要切换模式为 \033[42;37m 多端口 \033[0m ? (y/N)"
		echo
		read -p "(默认: n):" mode_yn
		[[ -z ${mode_yn} ]] && mode_yn="n"
		if [[ ${mode_yn} == [Yy] ]]; then
			port=`jq '.server_port' ${config_user_file}`
			setUser
			iptables_set
			cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "port_password":{
        "${ssport}":"${sspwd}"
    },
    "timeout": 120,
    "udp_timeout": 60,
    "method": "${ssmethod}",
    "protocol": "${ssprotocol}",
    "protocol_param": "${ssprotocol_param}",
    "obfs": "${ssobfs}",
    "obfs_param": "",
    "speed_limit_per_con": ${ssspeed_limit_per_con},
    "speed_limit_per_user": ${ssspeed_limit_per_user},
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
			RestartSSR
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo
		echo -e "	当前ShadowsocksR模式：\033[42;37m 多端口 \033[0m"
		echo
		echo -e "确定要切换模式为 \033[42;37m 单端口 \033[0m ? (y/N)"
		echo
		read -p "(默认: n):" mode_yn
		[[ -z ${mode_yn} ]] && mode_yn="n"
		if [[ ${mode_yn} == [Yy] ]]; then
			user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				iptables_del
			done
			setUser
			iptables_add
		cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": ${ssport},
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "${sspwd}",
    "timeout": 120,
    "udp_timeout": 60,
    "method": "${ssmethod}",
    "protocol": "${ssprotocol}",
    "protocol_param": "${ssprotocol_param}",
    "obfs": "${ssobfs}",
    "obfs_param": "",
    "speed_limit_per_con": ${ssspeed_limit_per_con},
    "speed_limit_per_user": ${ssspeed_limit_per_user},
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
			RestartSSR
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
List_multi_port_user(){
	user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[[ ${socat_total} = "0" ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现 多端口用户，请检查 !" && exit 1
	user_list_all=""
	user_id=0
	check_sys
	if [[ ${release} = "centos" ]]; then
		for((integer = 1; integer <= ${user_total}; integer++))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 用户密码: "${user_password}"\n"
		done
	else
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 用户密码: "${user_password}"\n"
		done
	fi
	echo
	echo -e "当前有 \033[42;37m "${user_total}" \033[0m 个用户配置。"
	echo -e ${user_list_all}
}
# 添加 多端口用户配置
Add_multi_port_user(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" = "null" ]] && echo -e "\033[41;37m [错误] \033[0m 当前ShadowsocksR模式为 单端口，请检查 !" && exit 1
	set_port_pass
	sed -i "7 i \"        \"${ssport}\":\"${sspwd}\"," ${config_user_file}
	sed -i "7s/^\"//" ${config_user_file}
	iptables_add
	RestartSSR
	echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 多端口用户 \033[42;37m [端口: ${ssport} , 密码: ${sspwd}] \033[0m 已添加!"
}
# 修改 多端口用户配置
Modify_multi_port_user(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" = "null" ]] && echo -e "\033[41;37m [错误] \033[0m 当前ShadowsocksR模式为 单端口，请检查 !" && exit 1
	echo "请输入数字 来选择你要修改的类型 :"
	echo "1. 修改 用户端口/密码"
	echo "2. 修改 全局协议/混淆"
	read -p "(默认回车取消):" modify_type
	[[ -z "${modify_type}" ]] && exit 1
	if [[ ${modify_type} == "1" ]]; then
		List_multi_port_user
		while true
		do
		echo -e "请选择并输入 你要修改的用户前面的数字 :"
		read -p "(默认回车取消):" del_user_num
		[[ -z "${del_user_num}" ]] && exit 1
		expr ${del_user_num} + 0 &>/dev/null
		if [ $? -eq 0 ]; then
			if [[ ${del_user_num} -ge 1 ]] && [[ ${del_user_num} -le ${user_total} ]]; then
				set_port_pass
				del_user_num_3=$[ $del_user_num + 6]
				port=`sed -n "${del_user_num_3}p" ${config_user_file} | awk -F ":" '{print $1}' | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				password=`sed -n "${del_user_num_3}p" ${config_user_file} | awk -F ":" '{print $2}' | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				sed -i 's/"'$(echo ${port})'":"'$(echo ${password})'"/"'$(echo ${ssport})'":"'$(echo ${sspwd})'"/g' ${config_user_file}
				iptables_set
				RestartSSR
				echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 多端口用户 \033[42;37m ${del_user_num} \033[0m 已修改!"
				break
			else
				echo "输入错误，请输入正确的数字 !"
			fi
		else
			echo "输入错误，请输入正确的数字 !"
		fi
		done	
	elif [[ ${modify_type} == "2" ]]; then
		set_others
		getUser
		set_config_method_obfs_protocol
		set_config_protocol_param
		set_config_speed_limit_per
		RestartSSR
		echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 加密方式/协议/混淆等 已修改!"
	fi
}
# 删除 多端口用户配置
Del_multi_port_user(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" = "null" ]] && echo -e "\033[41;37m [错误] \033[0m 当前ShadowsocksR模式为 单端口，请检查 !" && exit 1
	List_multi_port_user
	user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[[ "${user_total}" -le "1" ]] && echo -e "\033[41;37m [错误] \033[0m 当前仅剩下一个多端口用户，无法删除 !" && exit 1
	while true
	do
	echo -e "请选择并输入 你要删除的用户前面的数字 :"
	read -p "(默认回车取消):" del_user_num
	[[ -z "${del_user_num}" ]] && exit 1
	expr ${del_user_num} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${del_user_num} -ge 1 ]] && [[ ${del_user_num} -le ${user_total} ]]; then
			del_user_num_4=$[ $del_user_num + 6]
			port=`sed -n "${del_user_num_4}p" ${config_user_file} | awk -F ":" '{print $1}' | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			iptables_del
			del_user_num_1=$[ $del_user_num + 6 ]
			sed -i "${del_user_num_1}d" ${config_user_file}
			if [[ ${del_user_num} = ${user_total} ]]; then
				del_user_num_1=$[ $del_user_num_1 - 1 ]
				sed -i "${del_user_num_1}s/,$//g" ${config_user_file}
			fi
			RestartSSR
			echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 多端口用户 \033[42;37m ${del_user_num} \033[0m 已删除!"
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
}
# 显示用户连接信息
View_user_connection_info(){
	SSR_install_status
	check_sys
	if [[ ${release} = "debian" ]]; then
		debian_View_user_connection_info
	elif [[ ${release} = "ubuntu" ]]; then
		debian_View_user_connection_info
	elif [[ ${release} = "centos" ]]; then
		centos_View_user_connection_info
	fi
}
debian_View_user_connection_info(){
	now_mode=`jq '.port_password' ${config_user_file}`
	if [[ "${now_mode}" = "null" ]]; then
		now_mode="单端口模式" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_port=`jq '.server_port' ${config_user_file}`
		user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
		user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_list_all="1. 用户端口: "${user_port}", 链接端口的IP总数: "${user_IP_total}", 链接端口的IP: "${user_IP}"\n"
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前共有 \033[42;37m "${IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	else
		now_mode="多端口模式" && user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_list_all=""
		user_id=0
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
			user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 链接端口的IP总数: "${user_IP_total}" 链接端口的IP: "${user_IP}"\n"
		done
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前有 \033[42;37m "${user_total}" \033[0m 个用户配置，当前共有 \033[42;37m "${IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	fi
}
centos_View_user_connection_info(){
	now_mode=`jq '.port_password' ${config_user_file}`
	if [[ "${now_mode}" = "null" ]]; then
		now_mode="单端口模式" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $4}' |sort -u |wc -l`
		user_port=`jq '.server_port' ${config_user_file}`
		user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
		user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
		user_list_all="1. 用户端口: "${user_port}" 链接端口的IP总数: "${user_IP_total}" 链接端口的IP: "${user_IP}"\n"
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前共有 \033[42;37m "${IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	else
		now_mode="多端口模式" && user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $4}' |sort -u |wc -l`
		user_list_all=""
		user_id=0
		for((integer = 1; integer <= ${user_total}; integer++))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
			user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 链接端口的IP总数: "${user_IP_total}" 链接端口的IP: "${user_IP}"\n"
		done
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前有 \033[42;37m "${user_total}" \033[0m 个用户配置，当前共有 \033[42;37m "${IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	fi
}
SSR_start(){
	cd ${ssr_ss_file}
	nohup python server.py a >> ssserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ ! -z "${PID}" ]]; then
		viewUser
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR 已启动 !" && echo && echo ${Separator_1}
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 启动失败, 请检查日志 !"
	fi
}
#启动ShadowsocksR
StartSSR(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[[ ! -z ${PID} ]] && echo -e "\033[41;37m [错误] \033[0m 发现ShadowsocksR正在运行，请检查 !" && exit 1
	SSR_start
}
#停止ShadowsocksR
StopSSR(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m 发现ShadowsocksR没有运行，请检查 !" && exit 1
	kill -9 ${PID} && sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ -z "${PID}" ]]; then
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR 已停止 !" && echo && echo ${Separator_1}
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 停止失败 !"
	fi
}
#重启ShadowsocksR
RestartSSR(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[[ ! -z "${PID}" ]] && kill -9 ${PID}
	SSR_start
}
#查看 ShadowsocksR 日志
TailSSR(){
	[[ ! -f ${ssr_ss_file}"ssserver.log" ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现ShadowsocksR日志文件，请检查 !" && exit 1
	echo
	echo -e "使用 \033[41;37m Ctrl+C \033[0m 键退出查看日志 !"
	echo
	tail -f ${ssr_ss_file}"ssserver.log"
}
#查看 ShadowsocksR 状态
StatusSSR(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ -z "${PID}" ]]; then
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR 没有运行!" && echo && echo ${Separator_1}
	else
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR 正在运行(PID: ${PID}) !" && echo && echo ${Separator_1}
	fi
}
#安装锐速
installServerSpeeder(){
	[[ -d "/serverspeeder" ]] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 已安装 !" && exit 1
	cd /root
	#借用91yun.rog的开心版锐速
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder-all.sh
	bash serverspeeder-all.sh
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "serverspeeder" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		check_sys
		rc.local_serverspeed_set
		echo -e "\033[42;37m [信息] \033[0m 锐速(ServerSpeeder) 安装完成 !" && exit 1
	else
		echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 安装失败 !" && exit 1
	fi
}
#查看锐速状态
StatusServerSpeeder(){
	[[ ! -d "/serverspeeder" ]] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	/serverspeeder/bin/serverSpeeder.sh status
}
#停止锐速
StopServerSpeeder(){
	[[ ! -d "/serverspeeder" ]] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	/serverspeeder/bin/serverSpeeder.sh stop
}
#重启锐速
RestartServerSpeeder(){
	[[ ! -d "/serverspeeder" ]] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	/serverspeeder/bin/serverSpeeder.sh restart
}
#卸载锐速
UninstallServerSpeeder(){
	[[ ! -d "/serverspeeder" ]] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	echo "确定要卸载 锐速(ServerSpeeder) ? (y/N)"
	echo
	read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		rm -rf /root/serverspeeder-all.sh
		rm -rf /root/91yunserverspeeder
		rm -rf /root/91yunserverspeeder.tar.gz
		check_sys
		rc.local_serverspeed_del
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		echo && echo "锐速(ServerSpeeder) 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
BanBTPTSPAM(){
	wget -4qO- raw.githubusercontent.com/ToyoDAdoubi/doubi/master/Get_Out_Spam.sh | bash
}
InstallBBR(){
	echo -e "\033[42;37m [安装前 请注意] \033[0m"
	echo -e "1. 安装开启BBR，需要更换内核，存在更换失败等风险(重启后无法开机)"
	echo -e "2. 本脚本仅支持 Debian / Ubuntu 系统更换内核，OpenVZ虚拟化 不支持更换内核 !"
	echo -e "3. Debian 更换内核过程中会提示 [ 是否终止卸载内核 ] ，请选择 \033[42;37m NO \033[0m"
	echo -e "4. 安装BBR并重启后，需要重新运行脚本开启BBR \033[42;37m bash bbr.sh start \033[0m"
	echo
	echo "确定要安装 BBR ? (y/n)"
	read -p "(默认回车取消):" unyn
	[[ -z ${unyn} ]] && echo "安装已取消..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		wget -N --no-check-certificate https://softs.pw/Bash/bbr.sh && chmod +x bbr.sh && bash bbr.sh
	fi
}
SetCrontab_interval(){
	echo -e "\033[42;37m 格式说明 : \033[0m"
	echo -e " 格式为：\033[42;37m * * * * * \033[0m，分别对应 \033[42;37m 分钟 小时 日 月 星期 \033[0m"
	echo -e " 示例：\033[42;37m 30 2 * * * \033[0m，每天 凌晨2点30分时 重启一次"
	echo -e " 示例：\033[42;37m 30 2 */3 * * \033[0m，每隔3天 凌晨2点30分时 重启一次"
	echo -e " 示例：\033[42;37m 30 */2 * * * \033[0m，每天 每隔两小时 在30分时 重启一次"
	echo "请输入ShadowsocksR 定时重启的间隔"
	read -p "(默认: 每天凌晨2点0分 [0 2 * * *] ):" crontab_interval
	[[ -z "${crontab_interval}" ]] && crontab_interval="0 2 * * *"
	echo
	echo "——————————————————————————————"
	echo -e "	定时间隔 : \033[41;37m ${crontab_interval} \033[0m"
	echo "——————————————————————————————"
	echo
}
SetCrontab(){
	SSR_install_status
	check_sys
	if [[ ${release} = "centos" ]]; then
		corn_status=`service crond status`
	else
		corn_status=`service cron status`
	fi
	if [[ -z ${corn_status} ]]; then
		echo -e "\033[42;37m [信息] \033[0m 检测到没有安装 corn ，开始安装..."
		if [[ ${release} = "centos" ]]; then
			yum update && yum install crond -y
		else
			apt-get update && apt-get install cron -y
		fi
		if [[ ${release} = "centos" ]]; then
			corn_status=`service crond status`
		else
			corn_status=`service cron status`
		fi
		[[ -z ${corn_status} ]] && echo -e "\033[41;37m [错误] \033[0m corn 安装失败 !" && exit 1
	fi
	echo "请输入数字 来选择你要做什么"
	echo "1. 添加 定时任务"
	echo "2. 删除 定时任务"
	echo -e "\033[32m 注意： \033[0m暂时只能添加设置一个定时重启任务。"
	echo
	read -p "(默认回车取消):" setcron_select
	[[ -z "${setcron_select}" ]] && exit 1
	if [[ ${setcron_select} != "1" ]]; then
		if [[ ${setcron_select} != "2" ]]; then
			exit 1
		fi
	fi
	cron_ssr=`crontab -l | grep "${ssr_file}/${auto_restart_cron}" | wc -l`
	if [[ ${cron_ssr} > "0" ]]; then
		crontab -l > ${ssr_file}"/crontab.bak"
		sed -i "/\/etc\/shadowsocksr\/${auto_restart_cron}/d" ${ssr_file}"/crontab.bak"
		crontab ${ssr_file}"/crontab.bak"
		rm -rf ${ssr_file}"/crontab.bak"
		cron_ssr=`crontab -l | grep "${ssr_file}/${auto_restart_cron}" | wc -l`
		if [[ ${cron_ssr} > "0" ]]; then
			echo -e "\033[41;37m [错误] \033[0m corn 删除定时重启任务失败 !" && exit 1
		fi
	else
		if [[ ${setcron_select} == "2" ]]; then
			echo -e "\033[42;37m [信息] \033[0m corn 当前没有定时重启任务 !" && exit 1
		fi
	fi
	if [[ ${setcron_select} == "2" ]]; then
		echo -e "\033[42;37m [信息] \033[0m corn 删除定时重启任务成功 !" && exit 1
	fi
	SetCrontab_interval
	cat > ${ssr_file}"/"${auto_restart_cron}<<-EOF
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
server_ss_file="/etc/shadowsocksr/shadowsocks/"
server_file=${server_ss_file}"server.py"
config_user_file="/etc/shadowsocksr/user-config.json"

[ ! -e $config_user_file ] && exit 1
PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
[ ! -z "${PID}" ] && kill -9 ${PID}
cd ${server_ss_file}
nohup python server.py a >> ssserver.log 2>&1 &
sleep 2s
PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
if [ ! -z "${PID}" ]; then
	echo -e "	ShadowsocksR 重启完成 !"
else
	echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 启动失败 !"
fi
EOF
	if [[ -s ${ssr_file}"/"${auto_restart_cron} ]]; then
		chmod +x ${ssr_file}"/"${auto_restart_cron}
		crontab -l > ${ssr_file}"/crontab.bak"
		echo "${crontab_interval} /bin/bash ${ssr_file}/${auto_restart_cron}" >> ${ssr_file}"/crontab.bak"
		crontab ${ssr_file}"/crontab.bak"
		rm -rf ${ssr_file}"/crontab.bak"
		cron_ssr=`crontab -l | grep "${ssr_file}/${auto_restart_cron}" | wc -l`
		if [[ ${cron_ssr} > "0" ]]; then
			cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
			if [[ ${release} = "centos" ]]; then
				service crond restart
			else
				service cron restart
			fi
			echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 定时重启任务添加成功 !"
		else
			echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 定时重启任务添加失败 !" && exit 1
		fi
		
	else
		rm -rf ${ssr_file}"/"${auto_restart_cron}
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 重启脚本写入失败，请检查 !"
	fi
}
# 设置设备数
Client_limit(){
	SSR_install_status
	getUser
	if [[ ${protocol} != "origin" ]]; then
		protocol_1=`echo ${protocol} | sed 's/_compatible//g'`
		if [[ ${protocol} == ${protocol_1} ]]; then
			while true
			do
			echo
			echo -e "请输入 ShadowsocksR账号欲限制的设备数 (\033[32m auth_* 系列协议 不兼容原版才有效 \033[0m)"
			echo -e "\033[32m 注意： \033[0m该设备数限制，指的是每个端口同一时间能链接的客户端数量(多端口模式，每个端口都是独立计算)。"
			read -p "(回车 默认无限):" ssprotocol_param
			[[ -z "$ssprotocol_param" ]] && ssprotocol_param="" && break
			expr ${ssprotocol_param} + 0 &>/dev/null
			if [[ $? -eq 0 ]]; then
				if [[ ${ssprotocol_param} -ge 1 ]] && [[ ${ssprotocol_param} -le 99999 ]]; then
					echo && echo ${Separator_1} && echo -e "	设备数 : \033[32m${ssprotocol_param}\033[0m" && echo ${Separator_1} && echo
					break
				else
					echo "输入错误，请输入正确的数字 !"
				fi
			else
				echo "输入错误，请输入正确的数字 !"
			fi
			done
		else
			echo -e "\033[41;37m [错误] \033[0m ShadowsocksR当前协议为 兼容原版(${protocol})，限制设备数无效 !" && exit 1
		fi
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR当前协议为 原版(origin)，限制设备数无效 !" && exit 1
	fi
	set_config_protocol_param
	RestartSSR
	echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 设备数限制 已修改 !"
}
Speed_limit(){
	SSR_install_status
	# 设置单线程限速
	while true
	do
	echo
	echo -e "请输入 你要设置的每个端口 单线程 限速上限(单位：KB/S)"
	echo -e "\033[32m 注意： \033[0m这个指的是，每个端口 单线程的限速上限，多线程即无效。"
	read -p "(回车 默认无限):" ssspeed_limit_per_con
	[[ -z "$ssspeed_limit_per_con" ]] && ssspeed_limit_per_con=0 && break
	expr ${ssspeed_limit_per_con} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_con} -ge 1 ]] && [[ ${ssspeed_limit_per_con} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	单端口单线程 : \033[32m${ssspeed_limit_per_con} KB/S \033[0m" && echo ${Separator_1} && echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
	# 设置端口总限速
	while true
	do
	echo
	echo -e "请输入 你要设置的每个端口 总速度 限速上限(单位：KB/S)"
	echo -e "\033[32m 注意： \033[0m这个指的是，每个端口 总速度 限速上限，单个端口整体限速。"
	read -p "(回车 默认无限):" ssspeed_limit_per_user
	[[ -z "$ssspeed_limit_per_user" ]] && ssspeed_limit_per_user=0 && break
	expr ${ssspeed_limit_per_user} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_user} -ge 1 ]] && [[ ${ssspeed_limit_per_user} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	单端口总限速 : \033[32m${ssspeed_limit_per_user} KB/S \033[0m" && echo ${Separator_1} && echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
	getUser
	set_config_speed_limit_per
	RestartSSR
	echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 端口限速 已修改 !"
}

#菜单判断
echo
echo && echo "请输入一个数字来选择对应的选项。" && echo
echo -e "\033[32m  1. \033[0m安装 ShadowsocksR"
echo -e "\033[32m  2. \033[0m安装 libsodium(chacha20)"
echo -e "\033[32m  3. \033[0m显示 单/多端口 账号信息"
echo -e "\033[32m  4. \033[0m显示 单/多端口 连接信息"
echo -e "\033[32m  5. \033[0m修改 单端口用户配置"
echo -e "\033[32m  6. \033[0m手动 修改  用户配置"
echo -e "\033[32m  7. \033[0m卸载 ShadowsocksR"
echo -e "\033[32m  8. \033[0m更新 ShadowsocksR"
echo "——————————————————"
echo -e "\033[32m  9. \033[0m切换 单/多端口 模式"
echo -e "\033[32m 10. \033[0m添加 多端口用户配置"
echo -e "\033[32m 11. \033[0m修改 多端口用户配置"
echo -e "\033[32m 12. \033[0m删除 多端口用户配置"
echo "——————————————————"
echo -e "\033[32m 13. \033[0m启动 ShadowsocksR"
echo -e "\033[32m 14. \033[0m停止 ShadowsocksR"
echo -e "\033[32m 15. \033[0m重启 ShadowsocksR"
echo -e "\033[32m 16. \033[0m查看 ShadowsocksR 状态"
echo -e "\033[32m 17. \033[0m查看 ShadowsocksR 日志"
echo "——————————————————"
echo -e "\033[32m 18. \033[0m安装 锐速(ServerSpeeder)"
echo -e "\033[32m 19. \033[0m停止 锐速(ServerSpeeder)"
echo -e "\033[32m 20. \033[0m重启 锐速(ServerSpeeder)"
echo -e "\033[32m 21. \033[0m查看 锐速(ServerSpeeder) 状态"
echo -e "\033[32m 22. \033[0m卸载 锐速(ServerSpeeder)"
echo "——————————————————"
check_sys
[[ ${release} != "centos" ]] && echo -e "\033[32m 23. \033[0m安装 BBR(需更换内核, 存在风险)"
echo -e "\033[32m 24. \033[0m封禁 BT/PT/垃圾邮件(SPAM)"
echo -e "\033[32m 25. \033[0m设置 ShadowsocksR 定时重启"
echo -e "\033[32m 26. \033[0m设置 ShadowsocksR 设备数限制"
echo -e "\033[32m 27. \033[0m设置 ShadowsocksR 速度限制"
echo "——————————————————"
echo -e " 注意事项： 锐速/BBR 不支持 OpenVZ !"
if [[ -e $config_user_file ]]; then
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态：\033[42;37m 已安装 \033[0m 并 \033[42;37m 已启动 \033[0m"
	else
		echo -e " 当前状态：\033[42;37m 已安装 \033[0m 但 \033[41;37m 未启动 \033[0m"
	fi
	now_mode_1=`jq '.port_password' ${config_user_file}`
	if [[ "${now_mode_1}" = "null" ]]; then
		echo -e " 当前模式：\033[42;37m 单端口 \033[0m"
	else
		echo -e " 当前模式：\033[42;37m 多端口 \033[0m"
	fi
else
	echo -e " 当前状态：\033[41;37m 未安装 \033[0m"
fi
echo
read -p "(请输入 1-27 数字)：" num

case "$num" in
	1)
	installSSR
	;;
	2)
	installLibsodium
	;;
	3)
	viewUser
	;;
	4)
	View_user_connection_info
	;;
	5)
	modifyUser
	;;
	6)
	manuallyModifyUser
	;;
	7)
	UninstallSSR
	;;
	8)
	UpdateSSR
	;;
	9)
	Port_mode_switching
	;;
	10)
	Add_multi_port_user
	;;
	11)
	Modify_multi_port_user
	;;
	12)
	Del_multi_port_user
	;;
	13)
	StartSSR
	;;
	14)
	StopSSR
	;;
	15)
	RestartSSR
	;;
	16)
	StatusSSR
	;;
	17)
	TailSSR
	;;
	18)
	installServerSpeeder
	;;
	19)
	StopServerSpeeder
	;;
	20)
	RestartServerSpeeder
	;;
	21)
	StatusServerSpeeder
	;;
	22)
	UninstallServerSpeeder
	;;
	23)
	InstallBBR
	;;
	24)
	BanBTPTSPAM
	;;
	25)
	SetCrontab
	;;
	26)
	Client_limit
	;;
	27)
	Speed_limit
	;;
	*)
	echo '请选择并输入 1-27 的数字。'
	;;
esac