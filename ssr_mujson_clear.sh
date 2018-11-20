#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 7+/Ubuntu 14.04+
#	Description: ShadowsocksR mujson mode traffic clear script
#	Version: 1.0.1
#	Author: Toyo
#=================================================
SSR_file="/usr/local/shadowsocksr"
# 这里填写 mujson_mgr.py 文件的上层绝对路径
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Font_color_suffix="\033[0m" && Info="${Green_font_prefix}[信息]${Font_color_suffix}" && Error="${Red_font_prefix}[错误]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
check_ssr(){
	[[ ! -e ${SSR_file} ]] && echo -e "${Error} mujson_mgr.py 文件不存在或变量设定错误 !" && exit 1
}
scan_port(){
	cd "${SSR_file}"
	port_all=$(python "mujson_mgr.py" -l)
	[[ -z ${port_all} ]] && echo -e "${Error} 没有发现任何端口(用户) !" && exit 1
	port_num=$(echo "${port_all}"|wc -l)
	[[ ${port_num} = 0 ]] && echo -e "${Error} 没有发现任何端口(用户) !" && exit 1
}
clear_traffic(){
	for((integer = 1; integer <= ${port_num}; integer++))
	do
		port=$(echo -e "${port_all}"|sed -n "${integer}p"|awk '{print $NF}')
		[[ -z ${port} ]] && echo -e "${Error} 获取的端口(用户)为空 !" && exit 1
		result=$(python "mujson_mgr.py" -c -p "${port}")
		echo -e "${Info} 端口[${port}] 流量已清零 !"
	done
	echo -e "${Info} 所有端口(用户)流量已清零 !"
}
c_ssr(){
	check_ssr
	scan_port
	clear_traffic
}
action=$1
[[ -z $1 ]] && action=c
case "$action" in
    c)
    ${action}_ssr
    ;;
    *)
    echo -e "输入错误 !
 用法: c 清空 所有用户已使用流量"
    ;;
esac