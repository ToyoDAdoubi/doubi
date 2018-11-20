#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#       System Required: All
#       Description: Python HTTP Server
#       Version: 1.0.2
#       Author: Toyo
#       Blog: https://doub.io/wlzy-8/
#=================================================

sethttp(){
#设置端口
	while true
	do
	echo -e "请输入要开放的HTTP服务端口 [1-65535]"
	read -e -p "(默认端口: 8000):" httpport
	[[ -z "$httpport" ]] && httpport="8000"
	expr ${httpport} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${httpport} -ge 1 ]] && [[ ${httpport} -le 65535 ]]; then
			echo
			echo -e "	端口 : \033[41;37m ${httpport} \033[0m"
			echo
			break
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	else
		echo "输入错误, 请输入正确的端口。"
	fi
	done
	#设置目录
	echo "请输入要开放的目录(绝对路径)"
	read -e -p "(直接回车, 默认当前文件夹):" httpfile
	if [[ ! -z $httpfile ]]; then
		[[ ! -e $httpfile ]] && echo -e "\033[41;37m [错误] \033[0m 输入的目录不存在 或 当前用户无权限访问, 请检查!" && exit 1
	else
		httpfile=`echo $PWD`
	fi
	#最后确认
	echo
	echo "========================"
	echo "      请检查配置是否正确 !"
	echo
	echo -e "	端口 : \033[41;37m ${httpport} \033[0m"
	echo -e "	目录 : \033[41;37m ${httpfile} \033[0m"
	echo "========================"
	echo
	read -e -p "按任意键继续，如有错误，请使用 Ctrl + C 退出." var
}
iptables_add(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${httpport} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${httpport} -j ACCEPT
}
iptables_del(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
starthttp(){
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	[[ ! -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m SimpleHTTPServer 正着运行，请检查 !" && exit 1
	sethttp
	iptables_add
	cd ${httpfile}
	nohup python -m SimpleHTTPServer $httpport >> httpserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	if [[ -z $PID ]]; then
		echo -e "\033[41;37m [错误] \033[0m SimpleHTTPServer 启动失败 !" && exit 1
	else
		ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
		[[ -z "$ip" ]] && ip="VPS_IP"
		echo
		echo "HTTP服务 已启动 !"
		echo -e "浏览器访问，地址： \033[41;37m http://${ip}:${httpport} \033[0m "
		echo
	fi
}
stophttp(){
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现 SimpleHTTPServer 进程运行，请检查 !" && exit 1
	port=`netstat -lntp | grep ${PID} | awk '{print $4}' | awk -F ":" '{print $2}'`
	iptables_del
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[41;37m [错误] \033[0m SimpleHTTPServer 停止失败 !" && exit 1
	else
		echo
		echo "HTTP服务 已停止 !"
		echo
	fi
}

action=$1
[[ -z $1 ]] && action=start
case "$action" in
    start|stop)
    ${action}http
    ;;
    *)
    echo "输入错误 !"
    echo "用法: {start|stop}"
    ;;
esac