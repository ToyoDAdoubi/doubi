#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#       System Required: CentOS/Debian/Ubuntu
#       Description: iptables 封禁 BT、PT、SPAM（垃圾邮件）和自定义端口、关键词
#       Version: 1.0.10
#       Blog: https://doub.io/shell-jc2/
#=================================================

sh_ver="1.0.10"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"

smtp_port="25,26,465,587"
pop3_port="109,110,995"
imap_port="143,218,220,993"
other_port="24,50,57,105,106,158,209,1109,24554,60177,60179"
bt_key_word="torrent
.torrent
peer_id=
announce
info_hash
get_peers
find_node
BitTorrent
announce_peer
BitTorrent protocol
announce.php?passkey=
magnet:
xunlei
sandai
Thunder
XLLiveUD"

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
check_BT(){
	Cat_KEY_WORDS
	BT_KEY_WORDS=$(echo -e "$Ban_KEY_WORDS_list"|grep "torrent")
}
check_SPAM(){
	Cat_PORT
	SPAM_PORT=$(echo -e "$Ban_PORT_list"|grep "${smtp_port}")
}
Cat_PORT(){
	Ban_PORT_list=$(iptables -t filter -L OUTPUT -nvx --line-numbers|grep "REJECT"|awk '{print $13}')
}
Cat_KEY_WORDS(){
	Ban_KEY_WORDS_list=""
	Ban_KEY_WORDS_v6_list=""
	if [[ ! -z ${v6iptables} ]]; then
		Ban_KEY_WORDS_v6_text=$(${v6iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
		Ban_KEY_WORDS_v6_list=$(echo -e "${Ban_KEY_WORDS_v6_text}"|sed -r 's/.*\"(.+)\".*/\1/')
	fi
	Ban_KEY_WORDS_text=$(${v4iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
	Ban_KEY_WORDS_list=$(echo -e "${Ban_KEY_WORDS_text}"|sed -r 's/.*\"(.+)\".*/\1/')
}
View_PORT(){
	Cat_PORT
	echo -e "===============${Red_background_prefix} 当前已封禁 端口 ${Font_color_suffix}==============="
	echo -e "$Ban_PORT_list" && echo && echo -e "==============================================="
}
View_KEY_WORDS(){
	Cat_KEY_WORDS
	echo -e "==============${Red_background_prefix} 当前已封禁 关键词 ${Font_color_suffix}=============="
	echo -e "$Ban_KEY_WORDS_list" && echo -e "==============================================="
}
View_ALL(){
	echo
	View_PORT
	View_KEY_WORDS
	echo
}
Save_iptables_v4_v6(){
	if [[ ${release} == "centos" ]]; then
		if [[ ! -z "$v6iptables" ]]; then
			service ip6tables save
			chkconfig --level 2345 ip6tables on
		fi
		service iptables save
		chkconfig --level 2345 iptables on
	else
		if [[ ! -z "$v6iptables" ]]; then
			ip6tables-save > /etc/ip6tables.up.rules
			echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules" > /etc/network/if-pre-up.d/iptables
		else
			echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules" > /etc/network/if-pre-up.d/iptables
		fi
		iptables-save > /etc/iptables.up.rules
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Set_key_word() { $1 -t mangle -$3 OUTPUT -m string --string "$2" --algo bm --to 65535 -j DROP; }
Set_tcp_port() {
	[[ "$1" = "$v4iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with icmp-port-unreachable
	[[ "$1" = "$v6iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with tcp-reset
}
Set_udp_port() { $1 -t filter -$3 OUTPUT -p udp -m multiport --dports "$2" -j DROP; }
Set_SPAM_Code_v4(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
		do
		Set_tcp_port $v4iptables "$i" $s
		Set_udp_port $v4iptables "$i" $s
	done
}
Set_SPAM_Code_v4_v6(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
	do
		for j in $v4iptables $v6iptables
		do
			Set_tcp_port $j "$i" $s
			Set_udp_port $j "$i" $s
		done
	done
}
Set_PORT(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
		Set_tcp_port $v6iptables $PORT $s
		Set_udp_port $v6iptables $PORT $s
	elif [[ -n "$v4iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
	fi
	Save_iptables_v4_v6
}
Set_KEY_WORDS(){
	key_word_num=$(echo -e "${key_word}"|wc -l)
	for((integer = 1; integer <= ${key_word_num}; integer++))
		do
			i=$(echo -e "${key_word}"|sed -n "${integer}p")
			Set_key_word $v4iptables "$i" $s
			[[ ! -z "$v6iptables" ]] && Set_key_word $v6iptables "$i" $s
	done
	Save_iptables_v4_v6
}
Set_BT(){
	key_word=${bt_key_word}
	Set_KEY_WORDS
	Save_iptables_v4_v6
}
Set_SPAM(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_SPAM_Code_v4_v6
	elif [[ -n "$v4iptables" ]]; then
		Set_SPAM_Code_v4
	fi
	Save_iptables_v4_v6
}
Set_ALL(){
	Set_BT
	Set_SPAM
}
Ban_BT(){
	check_BT
	[[ ! -z ${BT_KEY_WORDS} ]] && echo -e "${Error} 检测到已封禁BT、PT 关键词，无需再次封禁 !" && exit 0
	s="A"
	Set_BT
	View_ALL
	echo -e "${Info} 已封禁BT、PT 关键词 !"
}
Ban_SPAM(){
	check_SPAM
	[[ ! -z ${SPAM_PORT} ]] && echo -e "${Error} 检测到已封禁SPAM(垃圾邮件) 端口，无需再次封禁 !" && exit 0
	s="A"
	Set_SPAM
	View_ALL
	echo -e "${Info} 已封禁SPAM(垃圾邮件) 端口 !"
}
Ban_ALL(){
	check_BT
	check_SPAM
	s="A"
	if [[ -z ${BT_KEY_WORDS} ]]; then
		if [[ -z ${SPAM_PORT} ]]; then
			Set_ALL
			View_ALL
			echo -e "${Info} 已封禁BT、PT 关键词 和 SPAM(垃圾邮件) 端口 !"
		else
			Set_BT
			View_ALL
			echo -e "${Info} 已封禁BT、PT 关键词 !"
		fi
	else
		if [[ -z ${SPAM_PORT} ]]; then
			Set_SPAM
			View_ALL
			echo -e "${Info} 已封禁SPAM(垃圾邮件) 端口 !"
		else
			echo -e "${Error} 检测到已封禁BT、PT 关键词 和 SPAM(垃圾邮件) 端口，无需再次封禁 !" && exit 0
		fi
	fi
}
UnBan_BT(){
	check_BT
	[[ -z ${BT_KEY_WORDS} ]] && echo -e "${Error} 检测到未封禁BT、PT 关键词，请检查 !" && exit 0
	s="D"
	Set_BT
	View_ALL
	echo -e "${Info} 已解封BT、PT 关键词 !"
}
UnBan_SPAM(){
	check_SPAM
	[[ -z ${SPAM_PORT} ]] && echo -e "${Error} 检测到未封禁SPAM(垃圾邮件) 端口，请检查 !" && exit 0
	s="D"
	Set_SPAM
	View_ALL
	echo -e "${Info} 已解封SPAM(垃圾邮件) 端口 !"
}
UnBan_ALL(){
	check_BT
	check_SPAM
	s="D"
	if [[ ! -z ${BT_KEY_WORDS} ]]; then
		if [[ ! -z ${SPAM_PORT} ]]; then
			Set_ALL
			View_ALL
			echo -e "${Info} 已解封BT、PT 关键词 和 SPAM(垃圾邮件) 端口 !"
		else
			Set_BT
			View_ALL
			echo -e "${Info} 已解封BT、PT 关键词 !"
		fi
	else
		if [[ ! -z ${SPAM_PORT} ]]; then
			Set_SPAM
			View_ALL
			echo -e "${Info} 已解封SPAM(垃圾邮件) 端口 !"
		else
			echo -e "${Error} 检测到未封禁BT、PT 关键词和 SPAM(垃圾邮件) 端口，请检查 !" && exit 0
		fi
	fi
}
ENTER_Ban_KEY_WORDS_type(){
	Type=$1
	Type_1=$2
	if [[ $Type_1 != "ban_1" ]]; then
		echo -e "请选择输入类型：
 1. 手动输入（只支持单个关键词）
 2. 本地文件读取（支持批量读取关键词，每行一个关键词）
 3. 网络地址读取（支持批量读取关键词，每行一个关键词）" && echo
		read -e -p "(默认: 1. 手动输入):" key_word_type
	fi
	[[ -z "${key_word_type}" ]] && key_word_type="1"
	if [[ ${key_word_type} == "1" ]]; then
		if [[ $Type == "ban" ]]; then
			ENTER_Ban_KEY_WORDS
		else
			ENTER_UnBan_KEY_WORDS
		fi
	elif [[ ${key_word_type} == "2" ]]; then
		ENTER_Ban_KEY_WORDS_file
	elif [[ ${key_word_type} == "3" ]]; then
		ENTER_Ban_KEY_WORDS_url
	else
		if [[ $Type == "ban" ]]; then
			ENTER_Ban_KEY_WORDS
		else
			ENTER_UnBan_KEY_WORDS
		fi
	fi
}
ENTER_Ban_PORT(){
	echo -e "请输入欲封禁的 端口（单端口/多端口/连续端口段）"
	if [[ ${Ban_PORT_Type_1} != "1" ]]; then
	echo -e "${Green_font_prefix}========示例说明========${Font_color_suffix}
 单端口：25（单个端口）
 多端口：25,26,465,587（多个端口用英文逗号分割）
 连续端口段：25:587（25-587之间的所有端口）" && echo
	fi
	read -e -p "(回车默认取消):" PORT
	[[ -z "${PORT}" ]] && echo "已取消..." && View_ALL && exit 0
}
ENTER_Ban_KEY_WORDS(){
	echo -e "请输入欲封禁的 关键词（域名等，仅支持单个关键词）"
	if [[ ${Type_1} != "ban_1" ]]; then
	echo -e "${Green_font_prefix}========示例说明========${Font_color_suffix}
 关键词：youtube，即禁止访问任何包含关键词 youtube 的域名。
 关键词：youtube.com，即禁止访问任何包含关键词 youtube.com 的域名（泛域名屏蔽）。
 关键词：www.youtube.com，即禁止访问任何包含关键词 www.youtube.com 的域名（子域名屏蔽）。
 更多效果自行测试（如关键词 .zip 即可禁止下载任何 .zip 后缀的文件）。" && echo
	fi
	read -e -p "(回车默认取消):" key_word
	[[ -z "${key_word}" ]] && echo "已取消..." && View_ALL && exit 0
}
ENTER_Ban_KEY_WORDS_file(){
	echo -e "请输入欲封禁/解封的 关键词本地文件（请使用绝对路径）" && echo
	read -e -p "(默认 读取脚本同目录下的 key_word.txt ):" key_word
	[[ -z "${key_word}" ]] && key_word="key_word.txt"
	if [[ -e "${key_word}" ]]; then
		key_word=$(cat "${key_word}")
		[[ -z ${key_word} ]] && echo -e "${Error} 文件内容为空 !" && View_ALL && exit 0
	else
		echo -e "${Error} 没有找到文件 ${key_word} !" && View_ALL && exit 0
	fi
}
ENTER_Ban_KEY_WORDS_url(){
	echo -e "请输入欲封禁/解封的 关键词网络文件地址（例如 http://xxx.xx/key_word.txt）" && echo
	read -e -p "(回车默认取消):" key_word
	[[ -z "${key_word}" ]] && echo "已取消..." && View_ALL && exit 0
	key_word=$(wget --no-check-certificate -t3 -T5 -qO- "${key_word}")
	[[ -z ${key_word} ]] && echo -e "${Error} 网络文件内容为空或访问超时 !" && View_ALL && exit 0
}
ENTER_UnBan_KEY_WORDS(){
	View_KEY_WORDS
	echo -e "请输入欲解封的 关键词（根据上面的列表输入完整准确的 关键词）" && echo
	read -e -p "(回车默认取消):" key_word
	[[ -z "${key_word}" ]] && echo "已取消..." && View_ALL && exit 0
}
ENTER_UnBan_PORT(){
	echo -e "请输入欲解封的 端口（根据上面的列表输入完整准确的 端口，包括逗号、冒号）" && echo
	read -e -p "(回车默认取消):" PORT
	[[ -z "${PORT}" ]] && echo "已取消..." && View_ALL && exit 0
}
Ban_PORT(){
	s="A"
	ENTER_Ban_PORT
	Set_PORT
	echo -e "${Info} 已封禁端口 [ ${PORT} ] !\n"
	Ban_PORT_Type_1="1"
	while true
	do
		ENTER_Ban_PORT
		Set_PORT
		echo -e "${Info} 已封禁端口 [ ${PORT} ] !\n"
	done
	View_ALL
}
Ban_KEY_WORDS(){
	s="A"
	ENTER_Ban_KEY_WORDS_type "ban"
	Set_KEY_WORDS
	echo -e "${Info} 已封禁关键词 [ ${key_word} ] !\n"
	while true
	do
		ENTER_Ban_KEY_WORDS_type "ban" "ban_1"
		Set_KEY_WORDS
		echo -e "${Info} 已封禁关键词 [ ${key_word} ] !\n"
	done
	View_ALL
}
UnBan_PORT(){
	s="D"
	View_PORT
	[[ -z ${Ban_PORT_list} ]] && echo -e "${Error} 检测到未封禁任何 端口 !" && exit 0
	ENTER_UnBan_PORT
	Set_PORT
	echo -e "${Info} 已解封端口 [ ${PORT} ] !\n"
	while true
	do
		View_PORT
		[[ -z ${Ban_PORT_list} ]] && echo -e "${Error} 检测到未封禁任何 端口 !" && exit 0
		ENTER_UnBan_PORT
		Set_PORT
		echo -e "${Info} 已解封端口 [ ${PORT} ] !\n"
	done
	View_ALL
}
UnBan_KEY_WORDS(){
	s="D"
	Cat_KEY_WORDS
	[[ -z ${Ban_KEY_WORDS_list} ]] && echo -e "${Error} 检测到未封禁任何 关键词 !" && exit 0
	ENTER_Ban_KEY_WORDS_type "unban"
	Set_KEY_WORDS
	echo -e "${Info} 已解封关键词 [ ${key_word} ] !\n"
	while true
	do
		Cat_KEY_WORDS
		[[ -z ${Ban_KEY_WORDS_list} ]] && echo -e "${Error} 检测到未封禁任何 关键词 !" && exit 0
		ENTER_Ban_KEY_WORDS_type "unban" "ban_1"
		Set_KEY_WORDS
		echo -e "${Info} 已解封关键词 [ ${key_word} ] !\n"
	done
	View_ALL
}
UnBan_KEY_WORDS_ALL(){
	Cat_KEY_WORDS
	[[ -z ${Ban_KEY_WORDS_text} ]] && echo -e "${Error} 检测到未封禁任何 关键词，请检查 !" && exit 0
	if [[ ! -z "${v6iptables}" ]]; then
		Ban_KEY_WORDS_v6_num=$(echo -e "${Ban_KEY_WORDS_v6_list}"|wc -l)
		for((integer = 1; integer <= ${Ban_KEY_WORDS_v6_num}; integer++))
			do
				${v6iptables} -t mangle -D OUTPUT 1
		done
	fi
	Ban_KEY_WORDS_num=$(echo -e "${Ban_KEY_WORDS_list}"|wc -l)
	for((integer = 1; integer <= ${Ban_KEY_WORDS_num}; integer++))
		do
			${v4iptables} -t mangle -D OUTPUT 1
	done
	Save_iptables_v4_v6
	View_ALL
	echo -e "${Info} 已解封所有关键词 !"
}
check_iptables(){
	v4iptables=`iptables -V`
	v6iptables=`ip6tables -V`
	if [[ ! -z ${v4iptables} ]]; then
		v4iptables="iptables"
		if [[ ! -z ${v6iptables} ]]; then
			v6iptables="ip6tables"
		fi
	else
		echo -e "${Error} 未安装 iptables 防火墙 !
请安装 iptables防火墙：
CentOS 系统：yum install iptables -y
Debian / Ubuntu 系统：apt-get install iptables -y"
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh" && chmod +x ban_iptables.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
check_iptables
action=$1
if [[ ! -z $action ]]; then
	[[ $action = "banbt" ]] && Ban_BT && exit 0
	[[ $action = "banspam" ]] && Ban_SPAM && exit 0
	[[ $action = "banall" ]] && Ban_ALL && exit 0
	[[ $action = "unbanbt" ]] && UnBan_BT && exit 0
	[[ $action = "unbanspam" ]] && UnBan_SPAM && exit 0
	[[ $action = "unbanall" ]] && UnBan_ALL && exit 0
fi
echo && echo -e " iptables防火墙 封禁管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc2 --

  ${Green_font_prefix}0.${Font_color_suffix} 查看 当前封禁列表
————————————
  ${Green_font_prefix}1.${Font_color_suffix} 封禁 BT、PT
  ${Green_font_prefix}2.${Font_color_suffix} 封禁 SPAM(垃圾邮件)
  ${Green_font_prefix}3.${Font_color_suffix} 封禁 BT、PT+SPAM
  ${Green_font_prefix}4.${Font_color_suffix} 封禁 自定义  端口
  ${Green_font_prefix}5.${Font_color_suffix} 封禁 自定义关键词
————————————
  ${Green_font_prefix}6.${Font_color_suffix} 解封 BT、PT
  ${Green_font_prefix}7.${Font_color_suffix} 解封 SPAM(垃圾邮件)
  ${Green_font_prefix}8.${Font_color_suffix} 解封 BT、PT+SPAM
  ${Green_font_prefix}9.${Font_color_suffix} 解封 自定义  端口
 ${Green_font_prefix}10.${Font_color_suffix} 解封 自定义关键词
 ${Green_font_prefix}11.${Font_color_suffix} 解封 所有  关键词
————————————
 ${Green_font_prefix}12.${Font_color_suffix} 升级脚本
" && echo
read -e -p " 请输入数字 [0-12]:" num
case "$num" in
	0)
	View_ALL
	;;
	1)
	Ban_BT
	;;
	2)
	Ban_SPAM
	;;
	3)
	Ban_ALL
	;;
	4)
	Ban_PORT
	;;
	5)
	Ban_KEY_WORDS
	;;
	6)
	UnBan_BT
	;;
	7)
	UnBan_SPAM
	;;
	8)
	UnBan_ALL
	;;
	9)
	UnBan_PORT
	;;
	10)
	UnBan_KEY_WORDS
	;;
	11)
	UnBan_KEY_WORDS_ALL
	;;
	12)
	Update_Shell
	;;
	*)
	echo "请输入正确数字 [0-12]"
	;;
esac