#!/bin/bash
#########################################################################
# File Name: Get_Out_Spam.sh
# Author: LookBack
# Email: admin#dwhd.org
# Version:
# Created Time: 2015年09月15日 星期二 22时30分38秒
#########################################################################

#=================================================
#       System Required: CentOS/Debian/Ubuntu
#       Description: 一键封禁 BT PT SPAM（垃圾邮件）
#       Version: 1.0.2
#       Blog: https://doub.io/wlzy-14/
#=================================================

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"

smpt_port="25,26,465,587"
pop_port="109,110,995"
imap_port="143,218,220,993"
other_port="24,50,57,105,106,158,209,1109,24554,60177,60179"
key_word=(Subject HELO SMTP
    "torrent" ".torrent" "peer_id=" "announce"
    "info_hash" "get_peers" "find_node"
    "BitTorrent" "announce_peer"
    "announce.php?passkey=")

v4iptables=`which iptables 2>/dev/null`
v6iptables=`which ip6tables 2>/dev/null`

# cat_rules() { $1 -t $2 -L OUTPUT -nvx --line-numbers; }
save_rules() {
    if [ -f /etc/redhat-release ]; then
        for i in $v4iptables $v6iptables;do ${i}-save > /etc/sysconfig/`basename $i`; done
    else
        for i in $v4iptables $v6iptables;do ${i}-save > /etc/`basename $i`.rules;done
        cat > /etc/network/if-pre-up.d/iptables << EOF
#!/bin/bash
${v4iptables}-restore < /etc/`basename $v4iptables`.rules
EOF
        chmod +x /etc/network/if-pre-up.d/iptables
    fi
}
# 添加
mangle_key_word() { $1 -t mangle -A OUTPUT -m string --string "$2" --algo bm --to 65535 -j DROP; }
tcp_port_DROP() {
    [ "$1" = "$v4iptables" ] && $1 -t filter -A OUTPUT -p tcp -m multiport --dports $2 -m state --state NEW,ESTABLISHED -j REJECT --reject-with icmp-port-unreachable
    [ "$1" = "$v6iptables" ] && $1 -t filter -A OUTPUT -p tcp -m multiport --dports $2 -m state --state NEW,ESTABLISHED -j REJECT --reject-with tcp-reset
}
udp_port_DROP() { $1 -t filter -A OUTPUT -p udp -m multiport --dports $2 -j DROP; }
# 删除
del_mangle_key_word() { $1 -t mangle -D OUTPUT -m string --string "$2" --algo bm --to 65535 -j DROP; }
del_tcp_port_DROP() {
    [ "$1" = "$v4iptables" ] && $1 -t filter -D OUTPUT -p tcp -m multiport --dports $2 -m state --state NEW,ESTABLISHED -j REJECT --reject-with icmp-port-unreachable
    [ "$1" = "$v6iptables" ] && $1 -t filter -D OUTPUT -p tcp -m multiport --dports $2 -m state --state NEW,ESTABLISHED -j REJECT --reject-with tcp-reset
}
del_udp_port_DROP() { $1 -t filter -D OUTPUT -p udp -m multiport --dports $2 -j DROP; }
# ========================= #
# 添加
add_iptables(){
	if [ -n "$v4iptables" -a -n "$v6iptables" ]; then
		for i in ${key_word[@]}; do for j in $v4iptables $v6iptables; do mangle_key_word $j $i; done; done
		for i in ${smpt_port} ${pop_port} ${imap_port} ${other_port}; do for j in $v4iptables $v6iptables; do tcp_port_DROP $j $i && udp_port_DROP $j $i; done; done
		save_rules && iptables -L -n && echo -e "${Info} iptables 防火墙 封禁BT PT SPAM(垃圾邮件)规则添加成功 !"
	elif [ -n "$v4iptables" ]; then
		for i in ${key_word[@]}; do mangle_key_word $v4iptables $i;done
		for i in ${smpt_port} ${pop_port} ${imap_port} ${other_port}; do tcp_port_DROP $v4iptables $i && udp_port_DROP $v4iptables $i; done
		save_rules && iptables -L -n && echo -e "${Info} iptables 防火墙 封禁BT PT SPAM(垃圾邮件)规则添加成功 !"
	else
		echo -e "${Error} 没有找到 iptables !"
	fi
}
# 删除
del_iptables(){
	if [ -n "$v4iptables" -a -n "$v6iptables" ]; then
		for i in ${key_word[@]}; do for j in $v4iptables $v6iptables; do del_mangle_key_word $j $i; done; done
		for i in ${smpt_port} ${pop_port} ${imap_port} ${other_port}; do for j in $v4iptables $v6iptables; do del_tcp_port_DROP $j $i && del_udp_port_DROP $j $i; done; done
		save_rules && iptables -L -n && echo -e "${Info} iptables 防火墙 封禁BT PT SPAM(垃圾邮件)规则删除成功 !"
	elif [ -n "$v4iptables" ]; then
		for i in ${key_word[@]}; do del_mangle_key_word $v4iptables $i;done
		for i in ${smpt_port} ${pop_port} ${imap_port} ${other_port}; do del_tcp_port_DROP $v4iptables $i && del_udp_port_DROP $v4iptables $i; done
		save_rules && iptables -L -n && echo -e "${Info} iptables 防火墙 封禁BT PT SPAM(垃圾邮件)规则删除成功 !"
	else
		echo -e "${Error} 没有找到 iptables !"
	fi
}
action=$1
[[ -z $1 ]] && action=add
case "$action" in
	add)
	add_iptables
	;;
	del)
	del_iptables
	;;
	*)
	echo -e "${Error} 用法: { add | del }"
	;;
esac
