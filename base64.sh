#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}" && Error="${Red_font_prefix}[错误]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
urlsafe_base64_d(){
	date=$(echo -n "$1"|sed 's/-/+/g;s/_/\//g'|base64 -d)
	echo -e "${date}"
}
set_type(){
	echo -e "你要干什么呢？
 ${Green_font_prefix}1.${Font_color_suffix} URL_Safe_Base64 加密文本
 ${Green_font_prefix}2.${Font_color_suffix} URL_Safe_Base64 解密文本"
	read -e -p "(默认:1):" enter_type
	[[ -z "${enter_type}" ]] && enter_type="1"
	if [[ ${enter_type} == "1" ]]; then
		set_text "1"
	elif [[ ${enter_type} == "2" ]]; then
		set_text "2"
	else
		set_text "1"
	fi
}
set_text(){
	echo "请输入要 URL_Safe_Base64 加密/解密 的文本"
	read -e -p "(默认回车取消):" text
	[[ -z "${text}" ]] && echo "已取消..." && exit 1
	[[ -z "${enter_type}" ]] && enter_type="1"
	if [[ $1 == "1" ]]; then
		echo && urlsafe_base64 "${text}" && echo
	elif [[ $1 == "2" ]]; then
		echo && urlsafe_base64_d "${text}" && echo
	else
		echo && urlsafe_base64 "${text}" && echo
	fi
}
set_type