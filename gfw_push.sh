#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: 监测IP是否被墙并推送消息至Telegram
#	Version: 1.0.4
#	Author: Toyo
#	Blog: https://doub.io/shell-jc8/
#=================================================

sh_ver="1.0.4"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
Crontab_file="/usr/bin/crontab"
CONF="${file_1}/gfw_push.conf"
LOG_file="${file_1}/gfw_push.log"
Test_link="www.189.cn
biz.10010.com
www.10086.cn"
Test_UA="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36
Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36
Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36 LBBROWSER
Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:62.0) Gecko/20100101 Firefox/62.0
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36 Edge/17.17134
Mozilla/5.0 (Linux; Android 8.0.0; MHA-AL00 Build/HUAWEIMHA-AL00) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Mobile Safari/537.36
Mozilla/5.0 (Linux; Android 7.0; LG-H850 Build/NRD90U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Mobile Safari/537.36
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36
Mozilla/5.0 (iPhone; CPU iPhone OS 12_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1
Mozilla/5.0 (iPhone; CPU iPhone OS 7_0_2 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) CriOS/30.0.1599.12 Mobile/11A501 Safari/8536.25 MicroMessenger/6.1.0
Mozilla/5.0 (iPad; CPU OS 12_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

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
check_crontab_name(){
	if [[ ${release} == "centos" ]]; then
		cron_name="crond"
	else
		cron_name="cron"
	fi
}
check_crontab_monitor_status(){
	crontab -l &> ".crontab_tmp"
	sed -i "/no crontab for/d" ".crontab_tmp"
	cron_config=$(cat ".crontab_tmp" | grep "gfw_push.sh monitor")
	rm -rf ".crontab_tmp"
	if [[ -z ${cron_config} ]]; then
		return 0
	else
		return 1
	fi
}
check_crontab_pid(){
	Cron_PID=$(ps -ef| grep "${cron_name}"| grep -v "grep" | grep -v "init.d" |grep -v "service" |awk '{print $2}')
	if [[ -z ${Cron_PID} ]]; then
		return 0
	else
		return 1
	fi
}
Install_crontab(){
	if [[ ! -e "${Crontab_file}" ]]; then
		echo -e "${Error} Crontab 没有安装，开始安装..."
		\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		if [[ ${release} == "centos" ]]; then
			yum update
			yum install "${cron_name}" -y
		else
			apt-get update
			apt-get install "${cron_name}" -y
		fi
		if [[ ! -e "${Crontab_file}" ]]; then
			echo -e "${Error} Crontab 安装失败，请检查！" && exit 1
		else
			echo -e "${Info} Crontab 安装成功！"
			sleep 2s
			check_crontab_pid
			[[ $? == 0 ]] && /etc/init.d/${cron_name} start
		fi
	else
		\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		/etc/init.d/${cron_name} restart
	fi
}
Set_Name(){
	echo "请输入该服务器的 [别名]（可选）
用于推送消息时，使你快速分辨服务器。支持中文，但请勿包含一些特殊符号，否则可能导致推送出错。"
	read -e -p "(默认为空):" new_name
	echo && echo "========================"
	echo -e "	别名 : ${Red_background_prefix} ${new_name} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_Token(){
	while true
	do
		echo -e "请输入推送机器人 [API密匙]
Token，通过 @notificationme_bot 机器人获取。
获取步骤：向机器人发送 /start 后，机器人会告诉一个API URL，例如：https://tgbot.lbyczf.com/sendMessage/abc，其中的 abc 就是API密匙。"
		read -e -p "(不能为空):" new_token
		if [[ ! -z "${new_token}" ]]; then
			echo && echo "========================"
			echo -e "	密匙 : ${Red_background_prefix} ${new_token} ${Font_color_suffix}"
			echo "========================" && echo
			break
		else
			echo -e "${Error} 请输入密匙。"
		fi
	done
}
Write_config(){
	cat > ${CONF}<<-EOF
NAME = ${new_name}
TOKEN = ${new_token}
SILL = ${SILL}
SILL_NOW = ${sill_new}
EOF
}
Write_config_now_sill(){
	new_name="${NAME}"
	new_token="${TOKEN}"
	Write_config
}
Read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} 脚本配置文件不存在 !" && exit 1
	NAME=$(cat ${CONF}|grep 'NAME = '|awk -F 'NAME = ' '{print $NF}')
	#[[ -z "${NAME}" ]] && NAME="NO-NAME"
	TOKEN=$(cat ${CONF}|grep 'TOKEN = '|awk -F 'TOKEN = ' '{print $NF}')
	[[ -z "${TOKEN}" ]] && echo -e "${Error} 脚本配置文件中API密匙为空(Token) !" && exit 1
	SILL=$(cat ${CONF}|grep 'SILL = '|awk -F 'SILL = ' '{print $NF}')
	[[ -z "${SILL}" ]] && SILL="3"
	SILL_NOW=$(cat ${CONF}|grep 'SILL_NOW = '|awk -F 'SILL_NOW = ' '{print $NF}')
	[[ -z "${SILL_NOW}" ]] && SILL_NOW="0"
}
POST_TG(){
	Get_IP
	if [[ -z "${NAME}" ]]; then
		wget -qO- --post-data="text=\`[疑似被墙警告]\`  —  \[\`${IP}\`]&parse_mode=Markdown&disable_notification=false"  "https://tgbot.lbyczf.com/sendMessage/${TOKEN}" >> ${LOG_file}
	else
		wget -qO- --post-data="text=\`[疑似被墙警告]\`  —  \[${NAME}] (\`${IP}\`)&parse_mode=Markdown&disable_notification=false"  "https://tgbot.lbyczf.com/sendMessage/${TOKEN}" >> ${LOG_file}
	fi
	echo "" >> ${LOG_file}
}
Get_IP(){
	IP=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${IP}" ]]; then
		IP=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${IP}" ]]; then
			IP=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${IP}" ]]; then
				IP="IP获取失败"
			fi
		fi
	fi
}
Add_Crontab(){
	crontab -l &> "$file_1/crontab.bak"
	sed -i "/no crontab for/d" "$file_1/crontab.bak"
	sed -i "/gfw_push.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/gfw_push.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	check_crontab_monitor_status
	if [[ $? == 0 ]]; then
		echo -e "${Error} 定时监控功能添加失败，请检查 !" && exit 1
	else
		echo -e "${Info} 定时监控功能添加成功 !"
	fi
}
Del_Crontab(){
	crontab -l &> "$file_1/crontab.bak"
	sed -i "/no crontab for/d" "$file_1/crontab.bak"
	sed -i "/gfw_push.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	check_crontab_monitor_status
	if [[ $? == 1 ]]; then
		echo -e "${Error} 定时监控功能取消失败，请检查 !" && exit 1
	else
		echo -e "${Info} 定时监控功能取消成功 !"
	fi
}
rand(){
	rand_min=$1
	rand_max=$(($2-$rand_min+1))
	rand_num=$(date +%s%N)
	echo $(($rand_num%$rand_max+$rand_min))
}
Test_SILL(){
	Detailed_output="${1}"
	Read_config
	echo "${SILL_NOW}|${SILL}"
	if [[ "${SILL_NOW}" == "${SILL}" ]]; then
		echo -e "${Error} 短时间内检测IP状态结果为被墙的次数已达到阈值 [${SILL}]，将不会继续检测。跳过..." && exit 1
	elif [[ "${SILL_NOW}" > "${SILL}" ]]; then
		sill_new="${SILL}"
		Write_config_now_sill
		echo -e "${Error} 短时间内检测IP状态结果为被墙的次数已达到阈值 [${SILL}]，将不会继续检测。跳过..." && exit 1
	else
		Test
	fi
}
Test(){
	Detailed_output="${1}"
	all_status_num="0"
	Return_status_debug=""
	status_num_debug=""
	Test_total=$(echo "${Test_link}"|wc -l)
	for((integer = 1; integer <= ${Test_total}; integer++))
	do
		UA_num=$(rand 1 12)
		UA=$(echo "${Test_UA}"|sed -n "${UA_num}p")
		now_URL=$(echo "${Test_link}"|sed -n "${integer}p")
		wget --spider -nv -t2 -T5 -4 -U "${UA}" "${now_URL}" -o "http_code.tmp"
		#wget --spider -nv -t2 -T5 -U "${UA}" "${now_URL}" &> /dev/null
		return_code=$(echo $?)
		#cat "http_code.tmp"
		#Return_status=$(cat "http_code.tmp"|sed -n '$p'|awk '{print $NF}')
		Return_status_debug="${Return_status_debug} | $(cat "http_code.tmp")"
		return_code_debug="${return_code_debug} | ${return_code}"
		#Return_status_debug="${Return_status_debug} | ${return_code}"
		#echo "${Return_status}"
		rm -rf "http_code.tmp"
		if [[ "${return_code}" == "0" ]]; then
			status_num="1"
			status_num_debug="${status_num_debug} | ${status_num}"
			[[ "${Detailed_output}" == "1" ]] && echo -e "${Info} 正常连接至 [${now_URL}] 。"
		else
			status_num="0"
			status_num_debug="${status_num_debug} | ${status_num}"
			[[ "${Detailed_output}" == "1" ]] && echo -e "${Error} 无法连接至 [${now_URL}] 。"
		fi
		all_status_num=$(echo $((${all_status_num}+${status_num})))
	done
}
crontab_monitor(){
	Test_SILL
	DATE=$(date "+%Y/%m/%d %H:%M:%S")
	if [[ "${all_status_num}" == "${Test_total}" ]]; then
		sill_new="0"
		Write_config_now_sill
		echo -e "${Info} ${DATE} 全部 URL 测试通过！该服务器没有被墙。"| tee -a ${LOG_file}
	elif [[ "${all_status_num}" == "0" ]]; then
		sill_new=$(echo $((${SILL_NOW}+1)))
		Write_config_now_sill
		echo "${Return_status_debug} / ${return_code_debug} / ${status_num_debug} / ${all_status_num}" >> ${LOG_file}
		echo -e "${Error} ${DATE} 全部 URL 测试失败！该服务器可能被墙，累计次数中..."| tee -a ${LOG_file}
		if [[ "${sill_new}" == "3" ]]; then
			echo -e "${Error} ${DATE} 疑似被墙次数累计超过 ${Test_total} 次，开始推送..."| tee -a ${LOG_file}
			POST_TG
		fi
	else
		sill_new="0"
		Write_config_now_sill
		echo -e "${Info} ${DATE} 部分 URL 测试通过！该服务器没有被墙，但可能与大陆链接的线路存在问题。"| tee -a ${LOG_file}
	fi
}
Init_config(){
	Set_Name
	Set_Token
	Install_crontab
	Add_Crontab
	SILL="3"
	sill_new="0"
	Write_config
	echo -e "${Info} 初始化配置完成，目前已启动定时检测IP被墙状态。"
}
Uninstall_config(){
	echo -e "确定要卸载(即清除定时任务及脚本配置文件) ? (y/N)"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		if [[ -e "${Crontab_file}" ]]; then
			Del_Crontab
		fi
		[[ -e "${CONF}" ]] && rm -rf "${CONF}"
		[[ -e "${LOG_file}" ]] && rm -rf "${LOG_file}"
		echo && echo "卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
Manual_detection(){
	Test "1"
	if [[ "${all_status_num}" == "${Test_total}" ]]; then
		echo -e "${Info} 全部 URL 测试通过！该服务器没有被墙。"
	elif [[ "${all_status_num}" == "0" ]]; then
		echo -e "${Error} 全部 URL 测试失败！该服务器可能被墙。"
	else
		echo -e "${Info} 部分 URL 测试通过！该服务器没有被墙，但可能与大陆链接的线路存在问题。"
	fi
}
Stop_monitor(){
	check_crontab_monitor_status
	if [[ $? == 1 ]]; then
		Read_config
		Del_Crontab
	else
		echo -e "${Error} 检测IP定时任务已经暂停。"
	fi
}
restart_monitor(){
	check_crontab_monitor_status
	if [[ $? == 1 ]]; then
		Read_config
		new_name="${NAME}"
		new_token="${TOKEN}"
		sill_new="0"
		Write_config
		echo -e "${Info} 检测IP阈值已归零。"
	else
		Read_config
		Add_Crontab
	fi
}
Set_config(){
	Read_config
	Set_Name
	Set_Token
	sill_new=${SILL_NOW}
	Write_config
	echo -e "${Info} 修改配置完成。"
}
View_config(){
	Read_config
	Get_IP
	echo -e "\n脚本配置信息：
————————————————
 地址\t: ${Green_font_prefix}${IP}${Font_color_suffix}
 别名\t: ${Green_font_prefix}${NAME}${Font_color_suffix}
 密匙\t: ${Green_font_prefix}${TOKEN}${Font_color_suffix}
 阈值\t: ${Green_font_prefix}${SILL_NOW}/${SILL}${Font_color_suffix}\n"
}
View_Log(){
	[[ ! -e ${LOG_file} ]] && echo -e "${Error} 脚本日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志(正常情况是没有使用日志记录的)" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${LOG_file}${Font_color_suffix} 命令。" && echo
	tail -f ${LOG_file}
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/gfw_push.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/gfw_push.sh" && chmod +x gfw_push.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
check_sys
check_crontab_name
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor
else
	echo && echo -e "  监测IP是否被墙脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/shell-jc8 ----
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 初始化
 ${Green_font_prefix} 2.${Font_color_suffix} 卸  载
————————————
 ${Green_font_prefix} 3.${Font_color_suffix} 手动 检测IP
 ${Green_font_prefix} 4.${Font_color_suffix} 暂停 监测IP
 ${Green_font_prefix} 5.${Font_color_suffix} 重启 监测IP(或清零阈值)
 —— 当暂停或脚本推送三次IP被墙信息后，
    可以用该选项使脚本继续监测IP。
————————————
 ${Green_font_prefix} 6.${Font_color_suffix} 设置 配置信息
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 配置信息
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 日志信息
————————————" && echo
	if [[ -e "${Crontab_file}" ]]; then
		check_crontab_monitor_status
		if [[ $? == 0 ]]; then
			echo -e " 当前状态: ${Red_font_prefix}未启动监测${Font_color_suffix}"
		else
			echo -e " 当前状态: ${Green_font_prefix}已启动监测${Font_color_suffix}"
		fi
		check_crontab_pid
		[[ $? == 0 ]] && echo -e " ${Error} 检查到 Crontab 没有运行，如果不是主动关闭的，请手动启动：/etc/init.d/${cron_name} start"
	else
		echo -e " 当前状态: ${Red_font_prefix}Crontab 未安装${Font_color_suffix}"
	fi
	echo
	read -e -p " 请输入数字 [0-8]:" num
	case "$num" in
		0)
		Update_Shell
		;;
		1)
		Init_config
		;;
		2)
		Uninstall_config
		;;
		3)
		Manual_detection
		;;
		4)
		Stop_monitor
		;;
		5)
		restart_monitor
		;;
		6)
		Set_config
		;;
		7)
		View_config
		;;
		8)
		View_Log
		;;
		*)
		echo "请输入正确数字 [0-8]"
		;;
	esac
fi