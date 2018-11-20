#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6/Debian/Ubuntu 14.04+
#	Description: Install the ShadowsocksR server
#	Version: 1.2.9
#	Author: Toyo
#	Blog: https://doub.io/ss-jc42/
#=================================================

#ssr_pid="/var/run/shadowsocks.pid"
ssr_file="/etc/shadowsocksr"
ssr_ss_file="/etc/shadowsocksr/shadowsocks"
config_file="/etc/shadowsocksr/config.json"
config_user_file="/etc/shadowsocksr/user-config.json"
Libsodiumr_file="/root/libsodium"
Libsodiumr_ver="1.0.11"
auto_restart_cron="auto_restart_cron.sh"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"

Separator_1="——————————————————————————————"
# 脚本文字变量(Translation)
Language(){
	if [[ ! -e "${PWD}/lang_en" ]]; then
		Word_default="默认"
		Word_unlimited="无限"
		Word_user="用户"
		Word_port="端口"
		Word_pass="密码"
		Word_method="加密"
		Word_protocol="协议"
		Word_obfs="混淆"
		Word_ss_like=" SS    链接"
		Word_ss_qr_code=" SS  二维码"
		Word_ssr_like=" SSR   链接"
		Word_ssr_qr_code=" SSR 二维码"
		Word_single_port="单端口"
		Word_multi_port="多端口"
		Word_current_mode="当前模式"
		Word_current_status="当前状态"
		Word_number_of_devices="设备数"
		Word_number_of_devices_limit="设备数限制"
		Word_single_threaded_speed_limit="单线程限速"
		Word_port_total_speed_limit="端口总限速"
		Word_the_installation_is_complete="安装完成"
		Word_installation_failed="安装失败"
		Word_uninstall_is_complete="卸载完成"
		Word_uninstall_cancelled="卸载已取消..."
		Word_canceled="已取消..."
		Word_cancel="取消"
		Word_startup_failed="启动失败"
		Word_stop_failing="停止失败"
		Word_stopped="已停止"
		Word_installed="已安装"
		Word_not_installed="未安装"
		Word_has_started="已启动"
		Word_have_not_started="未启动"
		Word_running="正在运行"
		Word_not_running="没有运行"
		Word_info="信息"
		Word_error="错误"
		Word_Prompt="提示"
		Word_timing_interval="定时间隔"
		Word_and="并"
		Word_but="但"
		Word_serverspeeder="锐速"
	
		Info_switch_single_port_mode="你确定要切换模式为 ${Word_single_port} ?[y/N]"
		Info_switch_multi_port_mode="你确定要切换模式为 ${Word_multi_port} ?[y/N]"
		Info_input_port="请输入ShadowsocksR ${Word_port} [1-65535]"
		Info_input_pass="请输入ShadowsocksR ${Word_pass}"
		Info_input_method="请输入数字 来选择ShadowsocksR ${Word_method}"
		Info_input_protocol="请输入数字 来选择ShadowsocksR ${Word_protocol}( auth_aes128_* 以后的协议不再支持 兼容原版 )"
		Info_input_number_of_devices="请输入 ShadowsocksR账号欲限制的设备数 (${Green_font_prefix} auth_* 系列协议 不兼容原版才有效 ${Font_color_suffix})"
		Prompt_number_of_devices="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}该设备数限制，指的是每个端口同一时间能链接的客户端数量(多端口模式，每个端口都是独立计算)。"
		Info_input_obfs="请输入数字 来选择ShadowsocksR ${Word_obfs}"
		Info_protocol_compatible="是否设置 协议 兼容原版 ( _compatible )? [Y/n] :"
		Info_obfs_compatible="是否设置 混淆 兼容原版 ( _compatible )? [Y/n] :"
		Info_protocol_obfs_compatible="是否设置 协议/混淆 兼容原版 ( _compatible )? [Y/n] :"
		Info_input_single_threaded_speed_limit="请输入 你要设置的每个端口 单线程 限速上限(单位：KB/S)"
		Prompt_input_single_threaded_speed_limit="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}这个指的是，每个端口 单线程的限速上限，多线程即无效。"
		Info_total_port_speed_limit="请输入 你要设置的每个端口 总速度 限速上限(单位：KB/S)"
		Prompt_total_port_speed_limit="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}这个指的是，每个端口 总速度 限速上限，单个端口整体限速。"
	
		Info_input_modify_the_type="请输入数字 来选择你要修改的类型 :
1. 修改 ${Word_port}/${Word_pass}
2. 修改 ${Word_method}/${Word_protocol}/${Word_obfs}"
		info_input_select_user_id_modified="请选择并输入 你要修改的用户前面的数字 :"
		Info_input_select_user_id_del="请选择并输入 你要删除的用户前面的数字 :"
		Prompt_method_protocol_obfs_modified="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ShadowsocksR ${Word_method}/${Word_protocol}/${Word_obfs}已修改!"

		Info_jq_installation_is_complete="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} JSON解析器 JQ 安装完成，继续..."
		Info_jq_is_installed="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} 检测到 JSON解析器 JQ 已安装，继续..."
		Info_uninstall_ssr="确定要卸载 ShadowsocksR ? [y/N]"
		Info_uninstall_server_speeder="确定要卸载 ${Word_serverspeeder} ? [y/N]"
		Info_install_bbr="确定要安装 BBR ? [y/n]"
		Info_install_bbr_0="${Green_font_prefix} [安装前 请注意] ${Font_color_suffix}
1. 安装开启BBR，需要更换内核，存在更换失败等风险(重启后无法开机)
2. 本脚本仅支持 Debian / Ubuntu 系统更换内核，OpenVZ虚拟化 不支持更换内核 !
3. Debian 更换内核过程中会提示 [ 是否终止卸载内核 ] ，请选择 ${Green_font_prefix} NO ${Font_color_suffix}
4. 安装BBR并重启后，需要重新运行脚本开启BBR ${Green_font_prefix} bash bbr.sh start ${Font_color_suffix}"
		Info_input_set_crontab_interval="请输入ShadowsocksR 定时重启的间隔"
		Info_input_set_crontab_interval_default="每天凌晨2点0分 [0 2 * * *]"
		Info_set_crontab_interval_0="${Green_font_prefix} 格式说明 : ${Font_color_suffix}
 格式: ${Green_font_prefix} * * * * * ${Font_color_suffix}，分别对应 ${Green_font_prefix} 分钟 小时 日 月 星期 ${Font_color_suffix}
 示例: ${Green_font_prefix} 30 2 * * * ${Font_color_suffix}，每天 凌晨2点30分时 重启一次
 示例: ${Green_font_prefix} 30 2 */3 * * ${Font_color_suffix}，每隔3天 凌晨2点30分时 重启一次
 示例: ${Green_font_prefix} 30 */2 * * * ${Font_color_suffix}，每天 每隔两小时 在30分时 重启一次"
		Info_no_cron_installed="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} 检测到没有安装 corn ，开始安装..."
		Info_input_set_cron="请输入数字 来选择你要做什么
1. 添加 定时任务
2. 删除 定时任务
 ${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}暂时只能添加设置一个定时重启任务。"
		Info_set_corn_status="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} corn 当前没有定时重启任务 !"
		Info_set_corn_del_success="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} corn 删除定时重启任务成功 !"
		Info_set_corn_add_success="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ShadowsocksR 定时重启任务添加成功 !"
		Info_limit_the_number_of_devices="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ShadowsocksR 设备数限制 已修改 !"
		Info_port_speed_limit="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ShadowsocksR 端口限速 已修改 !"
		Info_switch_language_english="Are you sure you want to switch the script language to English ? [y/n]"
		Info_switch_language_chinese="确定要切换脚本语言为 中文 ? [y/n]"
		Info_switch_language_1="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} Re-run the script to see the language after switching !"

		Errpr_input_num_error="${Red_font_prefix}[${Word_error}]${Font_color_suffix} 请输入正确的数字 !"
		Error_not_install_ssr="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 没有发现安装ShadowsocksR，请检查 !"
		Error_ssr_installed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR已安装 !"
		Error_no_multi_port_users_were_found="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 没有发现 多端口用户，请检查 !"
		Error_jq_installation_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} JSON解析器 JQ 安装失败 !"
		Error_does_not_support_the_system="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 本脚本不支持当前系统 !"
		Error_ssr_download_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR 下载失败 !"
		Error_ssr_failed_to_start="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR 启动失败 !"
		Error_the_current_mode_is_single_port="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 当前模式为 单端口，请检查 !"
		Error_the_current_mode_is_multi_port="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 当前模式为 多端口，请检查 !"
		Error_multi_port_user_remaining_one="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 当前多端口用户 仅剩一个，无法删除 !"
		Error_startup_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR 启动失败, 请检查日志 !"
		Error_no_log_found="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 没有找到日志文件，请检查 !"
		Error_server_speeder_installed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder} 已安装 !"
		Error_server_speeder_installation_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder} 安装失败 !"
		Error_server_speeder_not_installed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder} 没有安装，请检查 !"
		Error_cron_installation_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} corn 安装失败 !"
		Error_set_corn_del_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} corn 删除定时重启任务失败 !"
		Error_set_corn_add_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR 定时重启任务添加失败 !"
		Error_set_corn_Write_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR 定时重启脚本写入失败 !"
		Error_limit_the_number_of_devices_1="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR当前协议为 兼容原版(_compatible)，限制设备数无效 !"
		Error_limit_the_number_of_devices_2="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR当前协议为 原版(origin)，限制设备数无效 !"

		Prompt_method_libsodium="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}chacha20*等加密方式 需要安装 libsodium 支持库，否则会启动失败 !"
		Prompt_any_key="请按任意键继续，如有配置错误请使用 Ctrl+C 退出。"
		Prompt_check_if_the_configuration_is_incorrect="请检查Shadowsocks账号配置是否有误 !"
		Prompt_your_account_configuration="你的ShadowsocksR 账号配置 :"
		Prompt_ssr_status_on="ShadowsocksR 正在运行 !"
		Prompt_ssr_status_off="ShadowsocksR 没有运行 !"
		Prompt_tip="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}
 浏览器中，打开二维码链接，就可以看到二维码图片。
 协议和混淆后面的[ _compatible ]，指的是兼容原版Shadowsocks协议/混淆。"
		Prompt_total_number_of_users="当前用户配置总数为:"
		Prompt_total_number_of_ip="当前链接的IP总数为:"
		Prompt_the_currently_connected_ip="当前连接的IP:"
		Prompt_total_number_of_ip_number="IP数量:"
		Prompt_modify_multi_port_user="多端口用户已修改 !"
		Prompt_add_multi_port_user="多端口用户已添加 !"
		Prompt_del_multi_port_user="多端口用户已删除 !"
		Prompt_log="使用 ${Red_font_prefix} Ctrl+C ${Font_color_suffix} 键退出查看日志 !"
		Prompt_switch_language_chinese=" The current scripting language: English"
		Prompt_switch_language_english=" 当前脚本语言为:  中文"

#菜单
		Menu_prompt_1="请输入一个数字来选择对应的选项" 
		Menu_prompt_2="(请输入数字 0-27): "
		Menu_prompt_3="请选择并输入数字 0-27"
		Menu_options="${Green_font_prefix}  1. ${Font_color_suffix}安装 ShadowsocksR
${Green_font_prefix}  2. ${Font_color_suffix}安装 libsodium(chacha20)
${Green_font_prefix}  3. ${Font_color_suffix}显示 单/多端口 账号信息
${Green_font_prefix}  4. ${Font_color_suffix}显示 单/多端口 连接信息
${Green_font_prefix}  5. ${Font_color_suffix}修改 单端口用户配置
${Green_font_prefix}  6. ${Font_color_suffix}手动 修改  用户配置
${Green_font_prefix}  7. ${Font_color_suffix}卸载 ShadowsocksR
${Green_font_prefix}  8. ${Font_color_suffix}更新 ShadowsocksR
——————————————————
${Green_font_prefix}  9. ${Font_color_suffix}切换 单/多端口 模式
${Green_font_prefix} 10. ${Font_color_suffix}添加 多端口用户配置
${Green_font_prefix} 11. ${Font_color_suffix}修改 多端口用户配置
${Green_font_prefix} 12. ${Font_color_suffix}删除 多端口用户配置
——————————————————
${Green_font_prefix} 13. ${Font_color_suffix}启动 ShadowsocksR
${Green_font_prefix} 14. ${Font_color_suffix}停止 ShadowsocksR
${Green_font_prefix} 15. ${Font_color_suffix}重启 ShadowsocksR
${Green_font_prefix} 16. ${Font_color_suffix}查看 ShadowsocksR 状态
${Green_font_prefix} 17. ${Font_color_suffix}查看 ShadowsocksR 日志
——————————————————
${Green_font_prefix} 18. ${Font_color_suffix}安装 ${Word_serverspeeder}
${Green_font_prefix} 19. ${Font_color_suffix}停止 ${Word_serverspeeder}
${Green_font_prefix} 20. ${Font_color_suffix}重启 ${Word_serverspeeder}
${Green_font_prefix} 21. ${Font_color_suffix}查看 ${Word_serverspeeder} 状态
${Green_font_prefix} 22. ${Font_color_suffix}卸载 ${Word_serverspeeder}
——————————————————"
		Menu_options_bbr="${Green_font_prefix} 23. ${Font_color_suffix}安装 BBR(需更换内核, 存在风险)"
		Menu_options_other="${Green_font_prefix} 24. ${Font_color_suffix}封禁 BT/PT/垃圾邮件(SPAM)
${Green_font_prefix} 25. ${Font_color_suffix}设置 ShadowsocksR 定时重启
${Green_font_prefix} 26. ${Font_color_suffix}设置 ShadowsocksR 设备数限制
${Green_font_prefix} 27. ${Font_color_suffix}设置 ShadowsocksR 速度限制
——————————————————
${Green_font_prefix}  0. ${Font_color_suffix}The scripting language is English
 注意事项： ${Word_serverspeeder}/BBR 不支持 OpenVZ !"
	else
		Word_default="default"
		Word_unlimited="unlimited"
		Word_user="user"
		Word_port="port"
		Word_pass="pass"
		Word_method="method"
		Word_protocol="protocol"
		Word_obfs="obfs"
		Word_ss_like=" SS Like"
		Word_ss_qr_code=" SS QRcode"
		Word_ssr_like=" SSR Like"
		Word_ssr_qr_code=" SSR QRcode"
		Word_single_port="single_port"
		Word_multi_port="multi_port"
		Word_current_mode="Current_mode"
		Word_current_status="Current_status"
		Word_number_of_devices="number of devices"
		Word_number_of_devices_limit="number of devices limit"
		Word_single_threaded_speed_limit="single-threaded speed limit"
		Word_port_total_speed_limit="port total speed limit"
		Word_the_installation_is_complete="The installation is complete"
		Word_installation_failed="Installation failed"
		Word_uninstall_is_complete="Uninstall is complete"
		Word_uninstall_cancelled="Uninstall cancelled..."
		Word_canceled="Canceled..."
		Word_cancel="cancel"
		Word_startup_failed="Startup failed"
		Word_stop_failing="Stop failing"
		Word_stopped="Stopped"
		Word_installed="Installed"
		Word_not_installed="Not installed"
		Word_has_started="Has started"
		Word_have_not_started="Have not started"
		Word_running="Running"
		Word_not_running="Not running"
		Word_info="Info"
		Word_error="Error"
		Word_Prompt="Prompt"
		Word_timing_interval="Timing interval"
		Word_and="and"
		Word_but="but"
		Word_serverspeeder="ServerSpeeder"
	
		Info_switch_single_port_mode="Are you sure you want to switch mode to ${Word_single_port} ?[y/N]"
		Info_switch_multi_port_mode="Are you sure you want to switch mode to Word_multi_port ?[y/N]"
		Info_input_port="Please enter ShadowsocksR ${Word_port} [1-65535]"
		Info_input_pass="Please enter ShadowsocksR ${Word_pass}"
		Info_input_method="Please enter the number to select ShadowsocksR ${Word_method}"
		Info_input_protocol="Please enter the number to select ShadowsocksR ${Word_protocol}( auth_aes128_* 以后的协议不再支持 兼容原版 )"
		Info_input_number_of_devices="Please enter the number of devices that ShadowsocksR ports want to restrict (${Green_font_prefix} Auth_ * protocol is not compatible with the original version is valid! ${Font_color_suffix})"
		Prompt_number_of_devices="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}The number of devices is limited, referring to the number of clients that can be linked per port (multi_port mode, each port is independently calculated)."
		Info_input_obfs="Please enter the number to select ShadowsocksR ${Word_obfs}"
		Info_protocol_compatible="It is compatible with the original set protocol? ( _compatible ) [Y/n] :"
		Info_obfs_compatible="It is compatible with the original set obfs? ( _compatible ) [Y/n] :"
		Info_protocol_obfs_compatible="It is compatible with the original set protocol / obfs? ( _compatible ) [Y/n] :"
		Info_input_single_threaded_speed_limit="Please enter the maximum speed of each port you want to set for a single thread (in KB / S)"
		Prompt_input_single_threaded_speed_limit="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}This refers to the limit of each port single-threaded limit, multi-threaded that is invalid."
		Info_total_port_speed_limit="Please enter the maximum speed limit for each port you want to set (in KB / S)"
		Prompt_total_port_speed_limit="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}This refers to the total speed limit per port, the overall speed limit for a single port."
	
		Info_input_modify_the_type="Please enter a number to select the type you want to modify :
1. Modify ${Word_port}/${Word_pass}
2. Modify ${Word_method}/${Word_protocol}/${Word_obfs}"
		info_input_select_user_id_modified="Please select and enter the user ID you want to modify :"
		Info_input_select_user_id_del="Please select and enter the user ID you want to delete :"
		Prompt_method_protocol_obfs_modified="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ShadowsocksR ${Word_method}/${Word_protocol}/${Word_obfs} has been modified!"

		Info_jq_installation_is_complete="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} JSON parser JQ has been installed, continue ..."
		Info_jq_is_installed="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} JSON parser JQ installed, continues ..."
		Info_uninstall_ssr="Sure you want to uninstall ShadowsocksR ? [y/N]"
		Info_uninstall_server_speeder="Sure you want to uninstall ${Word_serverspeeder} ? [y/N]"
		Info_install_bbr="Sure you want to install the BBR ? [y/n]"
		Info_install_bbr_0="${Green_font_prefix} [Before installation, please note the following points] ${Font_color_suffix}
1. Install BBR, need to replace the kernel, there is a risk of replacement failure (can not boot) !
2. This script only supports Debian / Ubuntu system replacement kernel, OpenVZ virtualization does not support the replacement of the kernel !
3. In the process of replacing the kernel, you will be prompted to [ terminate the uninstall kernel ], Please select [${Green_font_prefix} NO ${Font_color_suffix}]!
4. After installing BBR and restart, you need to re-run the script to open BBR [${Green_font_prefix} bash bbr.sh start ${Font_color_suffix}] !"
		Info_input_set_crontab_interval="Please enter the interval at which ShadowsocksR reboots regularly"
		Info_input_set_crontab_interval_default="Every morning at 2:30 am [0 2 * * *]"
		Info_set_crontab_interval_0="${Green_font_prefix} Format Description : ${Font_color_suffix}
 Format: ${Green_font_prefix} * * * * * ${Font_color_suffix}, corresponding to ${Green_font_prefix} minutes / hour / day / month / week ${Font_color_suffix}
 Example: ${Green_font_prefix}30 2 * * * ${Font_color_suffix}, every day, 2:30 am, restart once
 Example: ${Green_font_prefix}30 2 * / 3 * * ${Font_color_suffix}, every 3 days, 2:30 am, restart once
 Example: ${Green_font_prefix}30 * / 2 * * * ${Font_color_suffix}, every day, every two hours at 30 minutes, restart once"
		Info_no_cron_installed="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} Detected no installation of corn, started to install ..."
		Info_input_set_cron="Please enter a number to choose what you want to do
1. Add a timed task
2. Delete the timed task
 ${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}Currently only add a regular restart task."
		Info_set_corn_status="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} There are currently no scheduled reboot task !"
		Info_set_corn_del_success="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} Corn Remove the timing reboot mission success !"
		Info_set_corn_add_success="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} Timed restart task was added successfully !"
		Info_limit_the_number_of_devices="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ShadowsocksR device limit has been modified !"
		Info_port_speed_limit="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ShadowsocksR port speed limit has been modified !"
		Info_switch_language_english="Are you sure you want to switch the script language to English ? [y/n]"
		Info_switch_language_chinese="确定要切换脚本语言为 中文 ? [y/n]"
		Info_switch_language_1="${Green_font_prefix} [${Word_info}] ${Font_color_suffix} 重新运行脚本即可看到切换后的语言 !"

		Errpr_input_num_error="${Red_font_prefix}[${Word_error}]${Font_color_suffix} Please enter the correct number !"
		Error_not_install_ssr="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} No installation ShadowsocksR, please check !"
		Error_ssr_installed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR is installed !"
		Error_no_multi_port_users_were_found="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} Do not find multi_port users, please check !"
		Error_jq_installation_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} JSON parser JQ installation failed !"
		Error_does_not_support_the_system="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} This script does not support the current system !"
		Error_ssr_download_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR download failed !"
		Error_ssr_failed_to_start="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR failed to start !"
		Error_the_current_mode_is_single_port="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} The current mode is single port, please check !"
		Error_the_current_mode_is_multi_port="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} The current mode is multi_port, please check !"
		Error_multi_port_user_remaining_one="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} The current multi_port users only one, can not be deleted !"
		Error_startup_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR failed to start, please check the log !"
		Error_no_log_found="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} Did not find the log file, please check it out !"
		Error_server_speeder_installed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder} installed !"
		Error_server_speeder_installation_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder}  installation failed !"
		Error_server_speeder_not_installed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder} is not installed, please check !"
		Error_cron_installation_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} Corn installation failed !"
		Error_set_corn_del_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} Delete the scheduled reboot task fails !"
		Error_set_corn_add_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} Timed restart task failed to add !"
		Error_set_corn_Write_failed="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} Timed restart script write failed !"
		Error_limit_the_number_of_devices_1="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} The current protocol is compatible with the original (_compatible), limit the number of devices is invalid !"
		Error_limit_the_number_of_devices_2="${Red_font_prefix} [${Word_error}] ${Font_color_suffix} The current agreement is the original (origin), limit the number of devices is invalid !"

		Prompt_method_libsodium="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix} Chacha20-* and other encryption methods need to install libsodium support library, otherwise it will fail to start !"
		Prompt_any_key="Please press any key to continue, if the configuration error please use Ctrl + C exit."
		Prompt_check_if_the_configuration_is_incorrect="请检查Shadowsocks账号配置是否有误 !"
		Prompt_your_account_configuration="Your ShadowsocksR account configuration :"
		Prompt_ssr_status_on="ShadowsocksR is running !"
		Prompt_ssr_status_off="ShadowsocksR is not running !"
		Prompt_tip="${Green_font_prefix} ${Word_Prompt}: ${Font_color_suffix}
 Browser, open the QRcode link, you can see the QRcode picture.
 Protocols and confusion behind [_compatible], referring to the original compatible Shadowsocks protocol / obfs."
		Prompt_total_number_of_users="Current total number of users:"
		Prompt_total_number_of_ip="The total number of currently linked IPs is:"
		Prompt_the_currently_connected_ip="The currently connected IP:"
		Prompt_total_number_of_ip_number="IP number:"
		Prompt_modify_multi_port_user="multi_port users have modified !"
		Prompt_add_multi_port_user="multi_port users have added !"
		Prompt_del_multi_port_user="multi_port user has been deleted !"
		Prompt_log="Use ${Red_font_prefix} Ctrl+C ${Font_color_suffix} to exit View Log !"
		Prompt_switch_language_chinese=" The current scripting language: English"
		Prompt_switch_language_english=" 当前脚本语言为:  中文"

#菜单
		Menu_prompt_1="Please enter a number to select the corresponding option" 
		Menu_prompt_2="(Please enter numbers 0-27): "
		Menu_prompt_3="Please select and enter numbers 0-27 !"
		Menu_options="${Green_font_prefix}  1. ${Font_color_suffix}Install Shadowsocks
${Green_font_prefix}  2. ${Font_color_suffix}Install libsodium (chacha20)
${Green_font_prefix}  3. ${Font_color_suffix}Display account information
${Green_font_prefix}  4. ${Font_color_suffix}Display connection information
${Green_font_prefix}  5. ${Font_color_suffix}Modify single-port user configuration
${Green_font_prefix}  6. ${Font_color_suffix}Manually modify user profiles
${Green_font_prefix}  7. ${Font_color_suffix}Uninstall Shadowsocks
${Green_font_prefix}  8. ${Font_color_suffix}Update Shadowsocks
——————————————————
${Green_font_prefix}  9. ${Font_color_suffix}Switch single / multi port mode
${Green_font_prefix} 10. ${Font_color_suffix}Add a multi_port user configuration
${Green_font_prefix} 11. ${Font_color_suffix}Modify multi_port user configuration
${Green_font_prefix} 12. ${Font_color_suffix}Remove the multi_port user configuration
——————————————————
${Green_font_prefix} 13. ${Font_color_suffix}Start Shadowsocks
${Green_font_prefix} 14. ${Font_color_suffix}Stop Shadowsocks
${Green_font_prefix} 15. ${Font_color_suffix}Restart Shadowsocks
${Green_font_prefix} 16. ${Font_color_suffix}View the ShadowsocksR state
${Green_font_prefix} 17. ${Font_color_suffix}View the ShadowsocksR log
——————————————————
${Green_font_prefix} 18. ${Font_color_suffix}Install ${Word_serverspeeder}
${Green_font_prefix} 19. ${Font_color_suffix}Stop ${Word_serverspeeder}
${Green_font_prefix} 20. ${Font_color_suffix}Restart ${Word_serverspeeder}
${Green_font_prefix} 21. ${Font_color_suffix}View the ${Word_serverspeeder} state
${Green_font_prefix} 22. ${Font_color_suffix}Uninstall ${Word_serverspeeder}
——————————————————"
		Menu_options_bbr="${Green_font_prefix} 23. ${Font_color_suffix}Install BBR(Need to replace the kernel, there is a risk)"
		Menu_options_other="${Green_font_prefix} 24. ${Font_color_suffix}Banned BT/PT/SPAM
${Green_font_prefix} 25. ${Font_color_suffix}Set ShadowsocksR scheduled reboot
${Green_font_prefix} 26. ${Font_color_suffix}Set the ShadowsocksR device limit
${Green_font_prefix} 27. ${Font_color_suffix}Set the ShadowsocksR speed limit
——————————————————
${Green_font_prefix}  0. ${Font_color_suffix}切换 脚本语言为中文
 Note: ${Word_serverspeeder} / BBR does not support OpenVZ !"
	fi
	Menu_status_1=" ${Word_current_status}: ${Green_font_prefix} ${Word_installed} ${Font_color_suffix} ${Word_and} ${Green_font_prefix} ${Word_has_started} ${Font_color_suffix}"
	Menu_status_2=" ${Word_current_status}: ${Green_font_prefix} ${Word_installed} ${Font_color_suffix} ${Word_but} ${Red_font_prefix} ${Word_have_not_started} ${Font_color_suffix}"
	Menu_status_3=" ${Word_current_status}: ${Red_font_prefix} ${Word_not_installed} ${Font_color_suffix}"
	Menu_mode_1=" ${Word_current_mode}: ${Green_font_prefix} ${Word_single_port} ${Font_color_suffix}"
	Menu_mode_2=" ${Word_current_mode}: ${Green_font_prefix} ${Word_multi_port} ${Font_color_suffix}"
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
	#bit=`uname -m`
}
SSR_install_status(){
	[[ ! -e $config_user_file ]] && echo -e "${Error_not_install_ssr}" && exit 1
}
#获取IP
getIP(){
	ip=`curl -m 10 -s "ipinfo.io/ip"`
	#ip=`wget -qO- -t1 -T2 ipinfo.io/ip`
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
	echo -e "${Info_input_port}"
	stty erase '^H' && read -p "(${Word_default}: 2333):" ssport
	[[ -z "$ssport" ]] && ssport="2333"
	expr ${ssport} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssport} -ge 1 ]] && [[ ${ssport} -le 65535 ]]; then
			echo && echo ${Separator_1} && echo -e "	${Word_port} : ${Green_font_prefix}${ssport}${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo -e "${Errpr_input_num_error}"
		fi
	else
		echo -e "${Errpr_input_num_error}"
	fi
	done
	#设置密码
	echo "${Info_input_pass}:"
	stty erase '^H' && read -p "(${Word_default}: doub.io):" sspwd
	[[ -z "${sspwd}" ]] && sspwd="doub.io"
	echo && echo ${Separator_1} && echo -e "	${Word_pass} : ${Green_font_prefix}${sspwd}${Font_color_suffix}" && echo ${Separator_1} && echo
}
# 设置 加密方式、协议和混淆等
set_others(){
	#设置加密方式
	echo "${Info_input_method}"
	echo " 1. rc4-md5"
	echo " 2. aes-128-ctr"
	echo " 3. aes-256-ctr"
	echo " 4. aes-256-cfb"
	echo " 5. aes-256-cfb8"
	echo " 6. camellia-256-cfb"
	echo " 7. chacha20"
	echo " 8. chacha20-ietf"
	echo -e "${Prompt_method_libsodium}"
	echo
	stty erase '^H' && read -p "(${Word_default}: 2. aes-128-ctr):" ssmethod
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
	echo && echo ${Separator_1} && echo -e "	${Word_method} : ${Green_font_prefix}${ssmethod}${Font_color_suffix}" && echo ${Separator_1} && echo
	#设置协议
	echo "${Info_input_protocol}"
	echo " 1. origin"
	echo " 2. auth_sha1_v4"
	echo " 3. auth_aes128_md5"
	echo " 4. auth_aes128_sha1"
	echo
	stty erase '^H' && read -p "(${Word_default}: 2. auth_sha1_v4):" ssprotocol
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
	echo && echo ${Separator_1} && echo -e "	${Word_protocol} : ${Green_font_prefix}${ssprotocol}${Font_color_suffix}" && echo ${Separator_1} && echo
	#设置混淆
	echo "${Info_input_obfs}"
	echo " 1. plain"
	echo " 2. http_simple"
	echo " 3. http_post"
	echo " 4. random_head"
	echo " 5. tls1.2_ticket_auth"
	echo
	stty erase '^H' && read -p "(${Word_default}: 5. tls1.2_ticket_auth):" ssobfs
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
	echo && echo ${Separator_1} && echo -e "	${Word_obfs} : ${Green_font_prefix}${ssobfs}${Font_color_suffix}" && echo ${Separator_1} && echo
	#询问是否设置 ${Word_obfs} 兼容原版
	if [[ ${ssprotocol} != "origin" ]]; then
		if [[ ${ssobfs} != "plain" ]]; then
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				stty erase '^H' && read -p "${Info_protocol_obfs_compatible}" yn1
				[[ -z "${yn1}" ]] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible" && ssprotocol=${ssprotocol}"_compatible"
			else
				stty erase '^H' && read -p "${Info_obfs_compatible}" yn1
				[[ -z "${yn1}" ]] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
			fi
		else
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				stty erase '^H' && read -p "${Info_protocol_compatible}" yn1
				[[ -z "${yn1}" ]] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssprotocol=${ssprotocol}"_compatible"
			fi
		fi
	else
		if [[ ${ssobfs} != "plain" ]]; then
			stty erase '^H' && read -p "${Info_obfs_compatible}" yn1
			[[ -z "${yn1}" ]] && yn1="y"
			[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
		fi
	fi
	if [[ ${ssprotocol} != "origin" ]]; then
		while true
		do
		echo
		echo -e "${Info_input_number_of_devices}"
		echo -e "${Prompt_number_of_devices}"
		stty erase '^H' && read -p "(${Word_default}: ${Word_unlimited}):" ssprotocol_param
		[[ -z "$ssprotocol_param" ]] && ssprotocol_param="" && break
		expr ${ssprotocol_param} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${ssprotocol_param} -ge 1 ]] && [[ ${ssprotocol_param} -le 99999 ]]; then
				echo && echo ${Separator_1} && echo -e "	${Word_number_of_devices} : ${Green_font_prefix}${ssprotocol_param}${Font_color_suffix}" && echo ${Separator_1} && echo
				break
			else
				echo "${Errpr_input_num_error}"
			fi
		else
			echo "${Errpr_input_num_error}"
		fi
		done
	fi
	# 设置单线程限速
	while true
	do
	echo
	echo -e "${Info_input_single_threaded_speed_limit}"
	echo -e "${Prompt_input_single_threaded_speed_limit}"
	stty erase '^H' && read -p "(${Word_default}: ${Word_unlimited}):" ssspeed_limit_per_con
	[[ -z "$ssspeed_limit_per_con" ]] && ssspeed_limit_per_con=0 && break
	expr ${ssspeed_limit_per_con} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_con} -ge 1 ]] && [[ ${ssspeed_limit_per_con} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	${Word_single_threaded_speed_limit} : ${Green_font_prefix}${ssspeed_limit_per_con} KB/S${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo "${Errpr_input_num_error}"
		fi
	else
		echo "${Errpr_input_num_error}"
	fi
	done
	# 设置端口总限速
	while true
	do
	echo
	echo -e "${Info_total_port_speed_limit}"
	echo -e "${Prompt_total_port_speed_limit}"
	stty erase '^H' && read -p "(${Word_default}: ${Word_unlimited}):" ssspeed_limit_per_user
	[[ -z "$ssspeed_limit_per_user" ]] && ssspeed_limit_per_user=0 && break
	expr ${ssspeed_limit_per_user} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_user} -ge 1 ]] && [[ ${ssspeed_limit_per_user} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	${Word_port_total_speed_limit} : ${Green_font_prefix}${ssspeed_limit_per_user} KB/S${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo "${Errpr_input_num_error}"
		fi
	else
		echo "${Errpr_input_num_error}"
	fi
	done
}
#设置用户账号信息
setUser(){
	set_port_pass
	set_others
	#最后确认
	[[ "${ssprotocol_param}" == "" ]] && ssprotocol_param="0(${Word_unlimited})"
	echo && echo ${Separator_1}
	echo " ${Prompt_check_if_the_configuration_is_incorrect}" && echo
	echo -e " ${Word_port}\t    : ${Green_font_prefix}${ssport}${Font_color_suffix}"
	echo -e " ${Word_pass}\t    : ${Green_font_prefix}${sspwd}${Font_color_suffix}"
	echo -e " ${Word_method}\t    : ${Green_font_prefix}${ssmethod}${Font_color_suffix}"
	echo -e " ${Word_protocol}\t    : ${Green_font_prefix}${ssprotocol}${Font_color_suffix}"
	echo -e " ${Word_obfs}\t    : ${Green_font_prefix}${ssobfs} ${Font_color_suffix}"
	echo -e " ${Word_number_of_devices_limit} : ${Green_font_prefix}${ssprotocol_param}${Font_color_suffix}"
	echo -e " ${Word_number_of_devices_limit} : ${Green_font_prefix}${ssspeed_limit_per_con} KB/S${Font_color_suffix}"
	echo -e " ${Word_port_total_speed_limit} : ${Green_font_prefix}${ssspeed_limit_per_user} KB/S${Font_color_suffix}"
	echo ${Separator_1} && echo
	stty erase '^H' && read -p "${Prompt_any_key}" var
	[[ "${ssprotocol_param}" = "0(${Word_unlimited})" ]] && ssprotocol_param=""
}
ss_link_qr(){
	SSbase64=`echo -n "${method}:${password}@${ip}:${port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	SSurl="ss://"${SSbase64}
	SSQRcode="http://doub.pw/qr/qr.php?text="${SSurl}
	ss_link="${Word_ss_like} : ${Green_font_prefix}${SSurl}${Font_color_suffix} \n${Word_ss_qr_code} : ${Green_font_prefix}${SSQRcode}${Font_color_suffix}"
}
ssr_link_qr(){
	SSRprotocol=`echo ${protocol} | sed 's/_compatible//g'`
	SSRobfs=`echo ${obfs} | sed 's/_compatible//g'`
	SSRPWDbase64=`echo -n "${password}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	SSRbase64=`echo -n "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	SSRurl="ssr://"${SSRbase64}
	SSRQRcode="http://doub.pw/qr/qr.php?text="${SSRurl}
	ssr_link="${Word_ssr_like} : ${Green_font_prefix}${SSRurl}${Font_color_suffix} \n${Word_ssr_qr_code} : ${Green_font_prefix}${SSRQRcode}${Font_color_suffix} \n "
}
ss_link_qr_1(){
	SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	#echo -e "${user_port}" && echo -e "${user_password}" && echo -e "${SSbase64}"
	SSurl="ss://"${SSbase64}
	SSQRcode="http://doub.pw/qr/qr.php?text="${SSurl}
	ss_link="${Word_ss_like} : ${Green_font_prefix}${SSurl}${Font_color_suffix} \n${Word_ss_qr_code} : ${Green_font_prefix}${SSQRcode}${Font_color_suffix}"
}
ssr_link_qr_1(){
	SSRprotocol=`echo ${protocol} | sed 's/_compatible//g'`
	SSRobfs=`echo ${obfs} | sed 's/_compatible//g'`
	SSRPWDbase64=`echo -n "${user_password}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	SSRbase64=`echo -n "${ip}:${user_port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
	#echo -e "${user_port}" && echo -e "${user_password}" && echo -e "${SSRbase64}"
	SSRurl="ssr://"${SSRbase64}
	SSRQRcode="http://doub.pw/qr/qr.php?text="${SSRurl}
	ssr_link="${Word_ssr_like} : ${Green_font_prefix}${SSRurl}${Font_color_suffix} \n${Word_ssr_qr_code} : ${Green_font_prefix}${SSRQRcode}${Font_color_suffix} \n "
}
#显示用户账号信息
viewUser(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ -z "${PID}" ]]; then
		ssr_status="${Red_font_prefix} ${Word_current_status}: ${Font_color_suffix} ShadowsocksR ${Word_not_running} !"
	else
		ssr_status="${Green_font_prefix} ${Word_current_status}: ${Font_color_suffix} ShadowsocksR ${Word_running} !"
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
		[[ -z ${protocol_param} ]] && protocol_param="0(${Word_unlimited})"
		clear
		echo "==================================================="
		echo
		echo -e " ${Prompt_your_account_configuration}"
		echo
		echo -e " I  P\t    : ${Green_font_prefix}${ip}${Font_color_suffix}"
		echo -e " ${Word_port}\t    : ${Green_font_prefix}${port}${Font_color_suffix}"
		echo -e " ${Word_pass}\t    : ${Green_font_prefix}${password}${Font_color_suffix}"
		echo -e " ${Word_method}\t    : ${Green_font_prefix}${method}${Font_color_suffix}"
		echo -e " ${Word_protocol}\t    : ${Green_font_prefix}${protocol}${Font_color_suffix}"
		echo -e " ${Word_obfs}\t    : ${Green_font_prefix}${obfs}${Font_color_suffix}"
		echo -e " ${Word_number_of_devices_limit} : ${Green_font_prefix}${protocol_param}${Font_color_suffix}"
		echo -e " ${Word_number_of_devices_limit} : ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"
		echo -e " ${Word_port_total_speed_limit} : ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}"
		echo -e "${ss_link}"
		echo -e "${ssr_link}"
		echo -e "${Prompt_tip}"
		echo
		echo -e ${ssr_status}
		echo
		echo "==================================================="
	else
		getUser
		[[ -z ${protocol_param} ]] && protocol_param="0(${Word_unlimited})"
		clear
		echo "==================================================="
		echo
		echo -e " ${Prompt_your_account_configuration}"
		echo
		echo -e " I  P\t    : ${Green_font_prefix}${ip}${Font_color_suffix}"
		echo -e " ${Word_method}\t    : ${Green_font_prefix}${method}${Font_color_suffix}"
		echo -e " ${Word_protocol}\t    : ${Green_font_prefix}${protocol}${Font_color_suffix}"
		echo -e " ${Word_obfs}\t    : ${Green_font_prefix}${obfs}${Font_color_suffix}"
		echo -e " ${Word_number_of_devices_limit} : ${Green_font_prefix}${protocol_param}${Font_color_suffix}"
		echo -e " ${Word_number_of_devices_limit} : ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"
		echo -e " ${Word_port_total_speed_limit} : ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}"
		echo
		user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		[[ ${socat_total} = "0" ]] && echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} 没有发现 多端口用户，请检查 !" && exit 1
		user_id=0
		check_sys
		if [[ ${release} = "centos" ]]; then
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_id=$[$user_id+1]
					#echo -e ${user_port} && echo -e ${user_password} && echo -e ${user_id}
				SSprotocol=`echo ${protocol} | awk -F "_" '{print $NF}'`
				SSobfs=`echo ${obfs} | awk -F "_" '{print $NF}'`
				if [[ ${protocol} = "origin" ]]; then
					if [[ ${obfs} = "plain" ]]; then
						ss_link_qr_1
						ssr_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							ss_link=""
						else
							ss_link_qr_1
						fi
					fi
				else
					if [[ ${SSprotocol} != "compatible" ]]; then
						ss_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							if [[ ${SSobfs} = "plain" ]]; then
								ss_link_qr_1
							else
								ss_link=""
							fi
						else
							ss_link_qr_1
						fi
					fi
				fi
				ssr_link_qr_1
				echo -e " ——————————${Green_font_prefix} ${Word_user} ${user_id} ${Font_color_suffix} ——————————"
				echo -e " ${Word_port}\t    : ${Green_font_prefix}${user_port}${Font_color_suffix}"
				echo -e " ${Word_pass}\t    : ${Green_font_prefix}${user_password}${Font_color_suffix}"
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
						ss_link_qr_1
						ssr_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							ss_link=""
						else
							ss_link_qr_1
						fi
					fi
				else
					if [[ ${SSprotocol} != "compatible" ]]; then
						ss_link=""
					else
						if [[ ${SSobfs} != "compatible" ]]; then
							if [[ ${SSobfs} = "plain" ]]; then
								ss_link_qr_1
							else
								ss_link=""
							fi
						else
							ss_link_qr_1
						fi
					fi
				fi
				ssr_link_qr_1
				echo -e " —————————— ${Green_font_prefix} ${Word_user} ${user_id} ${Font_color_suffix} ——————————"
				echo -e " ${Word_port}\t    : ${Green_font_prefix}${user_port}${Font_color_suffix}"
				echo -e " ${Word_pass}\t    : ${Green_font_prefix}${user_password}${Font_color_suffix}"
				echo -e "${ss_link}"
				echo -e "${ssr_link}"
			done
		fi
		echo -e "${Prompt_tip}"
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
		[[ -z ${JQ_ver} ]]&& echo -e "${Error_jq_installation_failed}" && exit 1
		echo -e "${Info_jq_installation_is_complete}" 
	else
		echo -e "${Info_jq_is_installed}"
	fi
}
rc.local_ss_set(){
#添加开机启动
	if [[ ${release} = "centos" ]]; then
		chmod +x /etc/rc.d/rc.local
		#sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.d/rc.local
		#sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.d/rc.local
		sed -i '/shadowsocksr/d' /etc/rc.d/rc.local
		sed -i '/python server.py/d' /etc/rc.d/rc.local
		echo -e "cd ${ssr_ss_file} && nohup python server.py a >> ssserver.log 2>&1 &" >> /etc/rc.d/rc.local
	else
		chmod +x /etc/rc.local
		sed -i '$d' /etc/rc.local
		#sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.local
		#sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.local
		sed -i '/shadowsocksr/d' /etc/rc.local
		sed -i '/python server.py/d' /etc/rc.local
		echo -e "cd ${ssr_ss_file} && nohup python server.py a >> ssserver.log 2>&1 &" >> /etc/rc.local
		echo -e "exit 0" >> /etc/rc.local
	fi
}
rc.local_ss_del(){
	if [[ ${release} = "centos" ]]; then
		#sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.d/rc.local
		#sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.d/rc.local
		sed -i '/shadowsocksr/d' /etc/rc.d/rc.local
		sed -i '/python server.py/d' /etc/rc.d/rc.local
	else
		#sed -i '/cd \/etc\/shadowsocksr\/shadowsocks\//d' /etc/rc.local
		#sed -i '/nohup python server.py a >> ssserver.log 2>&1 &/d' /etc/rc.local
		sed -i '/shadowsocksr/d' /etc/rc.local
		sed -i '/python server.py/d' /etc/rc.local
	fi
}
rc.local_serverspeed_set(){
#添加开机启动
	if [[ ${release} = "centos" ]]; then
		chmod +x /etc/rc.d/rc.local
		sed -i '/serverspeeder/d' /etc/rc.d/rc.local
		echo -e "/serverspeeder/bin/serverSpeeder.sh start" >> /etc/rc.d/rc.local
	else
		chmod +x /etc/rc.local
		sed -i '$d' /etc/rc.local
		sed -i '/serverspeeder/d' /etc/rc.local
		echo -e "/serverspeeder/bin/serverSpeeder.sh start" >> /etc/rc.local
		echo -e "exit 0" >> /etc/rc.local
	fi
}
rc.local_serverspeed_del(){
	if [[ ${release} = "centos" ]]; then
		sed -i '/serverspeeder/d' /etc/rc.d/rc.local
	else
		sed -i '/serverspeeder/d' /etc/rc.local
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
	[[ -e $config_user_file ]] && echo -e "${Error_ssr_installed}" && exit 1
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
		echo -e "${Error_does_not_support_the_system}" && exit 1
	fi
	#修改DNS为8.8.8.8
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	JQ_install
	cd /etc
	#git config --global http.sslVerify false
	env GIT_SSL_NO_VERIFY=true git clone -b manyuser https://github.com/shadowsocksr/shadowsocksr.git
	[[ ! -e ${config_file} ]] && echo -e "${Error_ssr_download_failed}" && exit 1
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
		echo -e "ShadowsocksR ${Word_the_installation_is_complete} !"
		echo -e "https://doub.io/ss-jc42/"
		echo
		echo "############################################################"
	else
		echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR ${Word_startup_failed} !"
	fi
}
installLibsodium(){
	# 系统判断
	check_sys
	if [[ ${release}  != "debian" ]]; then
		if [[ ${release}  != "ubuntu" ]]; then
			if [[ ${release}  != "centos" ]]; then
				echo -e "${Error_does_not_support_the_system}" && exit 1
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
	echo -e "Libsodium ${Word_the_installation_is_complete} !"
	echo -e "https://doub.io/ss-jc42/"
	echo && echo ${Separator_1}
}
#修改单端口用户配置
modifyUser(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" != "null" ]] && echo -e "${Error_the_current_mode_is_multi_port}" && exit 1
	getUser
	setUser
	#修改配置文件的密码 ${Word_port} 加密方式
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
	[[ ! -e $config_file ]] && echo -e "${Error_not_install_ssr}" && exit 1
	echo "${Info_uninstall_ssr}"
	echo
	stty erase '^H' && read -p "(${Word_default}: n):" unyn
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
		echo && echo "	ShadowsocksR ${Word_uninstall_is_complete} !" && echo
	else
		echo && echo "${Word_uninstall_cancelled}" && echo
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
		echo -e "	${Word_current_mode}: ${Green_font_prefix} ${Word_single_port} ${Font_color_suffix}"
		echo
		echo -e "${Info_switch_multi_port_mode}"
		echo
		stty erase '^H' && read -p "(${Word_default}: n):" mode_yn
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
			echo && echo "	${Word_canceled}" && echo
		fi
	else
		echo
		echo -e "	${Word_current_mode}: ${Green_font_prefix} ${Word_multi_port} ${Font_color_suffix}"
		echo
		echo -e "${Info_switch_single_port_mode}"
		echo
		stty erase '^H' && read -p "(${Word_default}: n):" mode_yn
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
			echo && echo "	${Word_canceled}" && echo
		fi
	fi
}
List_multi_port_user(){
	user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[[ ${socat_total} = "0" ]] && echo -e "${Error_no_multi_port_users_were_found}" && exit 1
	user_list_all=""
	user_id=0
	check_sys
	if [[ ${release} = "centos" ]]; then
		for((integer = 1; integer <= ${user_total}; integer++))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". ${Word_port}: "${user_port}" ${Word_pass}: "${user_password}"\n"
		done
	else
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". ${Word_port}: "${user_port}" ${Word_pass}: "${user_password}"\n"
		done
	fi
	echo
	echo -e "${Prompt_total_number_of_users} ${Green_font_prefix} "${user_total}" ${Font_color_suffix} "
	echo -e ${user_list_all}
}
# 添加 多端口用户配置
Add_multi_port_user(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" = "null" ]] && echo -e "${Error_the_current_mode_is_single_port}" && exit 1
	set_port_pass
	sed -i "7 i \"        \"${ssport}\":\"${sspwd}\"," ${config_user_file}
	sed -i "7s/^\"//" ${config_user_file}
	iptables_add
	RestartSSR
	echo -e "${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ${Prompt_add_multi_port_user} ${Green_font_prefix} [${Word_port}: ${ssport} , ${Word_pass}: ${sspwd}] ${Font_color_suffix} "
}
# 修改 多端口用户配置
Modify_multi_port_user(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" = "null" ]] && echo -e "${Error_the_current_mode_is_single_port}" && exit 1
	echo -e "${Info_input_modify_the_type}"
	stty erase '^H' && read -p "(${Word_default}: ${Word_cancel}):" modify_type
	[[ -z "${modify_type}" ]] && exit 1
	if [[ ${modify_type} == "1" ]]; then
		List_multi_port_user
		while true
		do
		echo -e "${info_input_select_user_id_modified}"
		stty erase '^H' && read -p "(${Word_default}: ${Word_cancel}):" del_user_num
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
				echo -e "${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ${Prompt_modify_multi_port_user} ${Green_font_prefix} ${del_user_num} ${Font_color_suffix} "
				break
			else
				echo "${Errpr_input_num_error}"
			fi
		else
			echo "${Errpr_input_num_error}"
		fi
		done	
	elif [[ ${modify_type} == "2" ]]; then
		set_others
		getUser
		set_config_method_obfs_protocol
		set_config_protocol_param
		set_config_speed_limit_per
		RestartSSR
		echo -e "${Prompt_method_protocol_obfs_modified}"
	fi
}
# 删除 多端口用户配置
Del_multi_port_user(){
	SSR_install_status
	now_mode=`jq '.port_password' ${config_user_file}`
	[[ "${now_mode}" = "null" ]] && echo -e "${Error_the_current_mode_is_single_port}" && exit 1
	List_multi_port_user
	user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[[ "${user_total}" -le "1" ]] && echo -e "${Error_multi_port_user_remaining_one}" && exit 1
	while true
	do
	echo -e "${Info_input_select_user_id_del}"
	stty erase '^H' && read -p "(${Word_default}: ${Word_cancel}):" del_user_num
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
			echo -e "${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ${Prompt_del_multi_port_user} ${Green_font_prefix} ${del_user_num} ${Font_color_suffix} "
			break
		else
			echo "${Errpr_input_num_error}"
		fi
	else
		echo "${Errpr_input_num_error}"
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
		now_mode="${Word_single_port}" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_port=`jq '.server_port' ${config_user_file}`
		user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
		user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_list_all="1. ${Word_port}: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, ${Prompt_total_number_of_ip_number} ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, ${Prompt_the_currently_connected_ip} ${Green_font_prefix}"${user_IP}"${Font_color_suffix}\n"
		echo -e "${Word_current_mode} ${Green_font_prefix} "${now_mode}" ${Font_color_suffix} 。"
		echo -e ${user_list_all}
	else
		now_mode="${Word_multi_port}" && user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_list_all=""
		user_id=0
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
			user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". ${Word_port}: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, ${Prompt_total_number_of_ip_number} ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, ${Prompt_the_currently_connected_ip} ${Green_font_prefix}"${user_IP}"${Font_color_suffix}\n"
		done
		echo -e "${Word_current_mode} ${Green_font_prefix} "${now_mode}" ${Font_color_suffix} ，${Word_current_mode} ${Green_font_prefix} "${user_total}" ${Font_color_suffix} ，${Prompt_total_number_of_ip} ${Green_font_prefix} "${IP_total}" ${Font_color_suffix} "
		echo -e ${user_list_all}
	fi
}
centos_View_user_connection_info(){
	now_mode=`jq '.port_password' ${config_user_file}`
	if [[ "${now_mode}" = "null" ]]; then
		now_mode="${Word_single_port}" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $4}' |sort -u |wc -l`
		user_port=`jq '.server_port' ${config_user_file}`
		user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
		user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
		user_list_all="1. ${Word_port}: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, ${Prompt_total_number_of_ip_number} ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, ${Prompt_the_currently_connected_ip} ${Green_font_prefix}"${user_IP}"${Font_color_suffix}\n"
		echo -e "${Word_current_mode} ${Green_font_prefix} "${now_mode}" ${Font_color_suffix} 。"
		echo -e ${user_list_all}
	else
		now_mode="${Word_multi_port}" && user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $4}' |sort -u |wc -l`
		user_list_all=""
		user_id=0
		for((integer = 1; integer <= ${user_total}; integer++))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
			user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". ${Word_port}: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, ${Prompt_total_number_of_ip_number} ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, ${Prompt_the_currently_connected_ip} ${Green_font_prefix}"${user_IP}"${Font_color_suffix}\n"
		done
		echo -e "${Word_current_mode} ${Green_font_prefix} "${now_mode}" ${Font_color_suffix} ，${Word_current_mode} ${Green_font_prefix} "${user_total}" ${Font_color_suffix} ，${Prompt_total_number_of_ip} ${Green_font_prefix} "${IP_total}" ${Font_color_suffix} "
		echo -e ${user_list_all}
	fi
}
SSR_start(){
	cd ${ssr_ss_file}
	nohup python server.py a > ssserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ ! -z "${PID}" ]]; then
		viewUser
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR ${Word_has_started} !" && echo && echo ${Separator_1}
	else
		echo -e "${Error_startup_failed}"
	fi
}
#启动ShadowsocksR
StartSSR(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[[ ! -z ${PID} ]] && echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR ${Word_running} !" && exit 1
	SSR_start
}
#停止ShadowsocksR
StopSSR(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[[ -z $PID ]] && echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR ${Word_not_running} !" && exit 1
	kill -9 ${PID} && sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ -z "${PID}" ]]; then
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR ${Word_stopped} !" && echo && echo ${Separator_1}
	else
		echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR ${Word_stop_failing} !"
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
	[[ ! -e ${ssr_ss_file}"/ssserver.log" ]] && echo -e "${Error_no_log_found}" && exit 1
	echo && echo -e "${Prompt_log}" && echo
	tail -f ${ssr_ss_file}"/ssserver.log"
}
#查看 ShadowsocksR 状态
StatusSSR(){
	SSR_install_status
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ -z "${PID}" ]]; then
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR ${Word_not_running} !" && echo && echo ${Separator_1}
	else
		echo ${Separator_1} && echo && echo -e "	ShadowsocksR ${Word_running} (PID: ${PID}) !" && echo && echo ${Separator_1}
	fi
}
#安装锐速
installServerSpeeder(){
	[[ -e "/serverspeeder" ]] && echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder} ${Word_installed} !" && exit 1
	cd /root
	#借用91yun.rog的开心版锐速
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder-all.sh
	bash serverspeeder-all.sh
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "serverspeeder" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		check_sys
		rc.local_serverspeed_set
		echo -e "${Green_font_prefix} [${Word_info}] ${Font_color_suffix} ${Word_serverspeeder} ${Word_the_installation_is_complete} !" && exit 1
	else
		echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ${Word_serverspeeder} ${Word_installation_failed} !" && exit 1
	fi
}
#查看锐速状态
StatusServerSpeeder(){
	[[ ! -e "/serverspeeder" ]] && echo -e "${Error_server_speeder_not_installed}" && exit 1
	/serverspeeder/bin/serverSpeeder.sh status
}
#停止锐速
StopServerSpeeder(){
	[[ ! -e "/serverspeeder" ]] && echo -e "${Error_server_speeder_not_installed}" && exit 1
	/serverspeeder/bin/serverSpeeder.sh stop
}
#重启锐速
RestartServerSpeeder(){
	[[ ! -e "/serverspeeder" ]] && echo -e "${Error_server_speeder_not_installed}" && exit 1
	/serverspeeder/bin/serverSpeeder.sh restart
}
#卸载锐速
UninstallServerSpeeder(){
	[[ ! -e "/serverspeeder" ]] && echo -e "${Error_server_speeder_not_installed}" && exit 1
	echo "${Info_uninstall_server}"
	echo
	stty erase '^H' && read -p "(${Word_default}: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		rm -rf /root/serverspeeder-all.sh
		rm -rf /root/91yunserverspeeder
		rm -rf /root/91yunserverspeeder.tar.gz
		check_sys
		rc.local_serverspeed_del
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		echo && echo "${Word_serverspeeder} ${Word_uninstall_is_complete} !" && echo
	else
		echo && echo "${Word_uninstall_cancelled}" && echo
	fi
}
BanBTPTSPAM(){
	wget -4qO- raw.githubusercontent.com/ToyoDAdoubi/doubi/master/Get_Out_Spam.sh | bash
}
InstallBBR(){
	echo -e "${Info_install_bbr_0}"
	echo
	echo "${Info_install_bbr}"
	stty erase '^H' && read -p "(${Word_default}: ${Word_cancel}):" unyn
	[[ -z ${unyn} ]] && echo "${Word_canceled}" && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		wget -N --no-check-certificate https://softs.pw/Bash/bbr.sh && chmod +x bbr.sh && bash bbr.sh
	fi
}
SetCrontab_interval(){
	echo -e "${Info_set_crontab_interval_0}"
	echo "${Info_input_set_crontab_interval}"
	stty erase '^H' && read -p "(${Word_default}: ${Info_input_set_crontab_interval_default} ):" crontab_interval
	[[ -z "${crontab_interval}" ]] && crontab_interval="0 2 * * *"
	echo
	echo "——————————————————————————————"
	echo -e "	${Word_timing_interval} : ${Red_font_prefix} ${crontab_interval} ${Font_color_suffix}"
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
		echo -e "${Info_no_cron_installed}"
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
		[[ -z ${corn_status} ]] && echo -e "${Error_cron_installation_failed}" && exit 1
	fi
	echo -e "${Info_input_set_cron}"
	echo
	stty erase '^H' && read -p "(${Word_default} :${Word_cancel}):" setcron_select
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
			echo -e "${Error_set_corn_del_failed}" && exit 1
		fi
	else
		if [[ ${setcron_select} == "2" ]]; then
			echo -e "${Info_set_corn_status}" && exit 1
		fi
	fi
	if [[ ${setcron_select} == "2" ]]; then
		echo -e "${Info_set_corn_del_success}" && exit 1
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
	echo -e "${Red_font_prefix} [${Word_error}] ${Font_color_suffix} ShadowsocksR 启动失败 !"
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
			echo -e "${Info_set_corn_add_success}"
		else
			echo -e "${Error_set_corn_add_failed}" && exit 1
		fi
		
	else
		rm -rf ${ssr_file}"/"${auto_restart_cron}
		echo -e "${Error_set_corn_Write_failed}"
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
			echo -e "${Info_input_number_of_devices}"
			echo -e "${Prompt_number_of_devices}"
			stty erase '^H' && read -p "(${Word_default}: ${Word_unlimited}):" ssprotocol_param
			[[ -z "$ssprotocol_param" ]] && ssprotocol_param="" && break
			expr ${ssprotocol_param} + 0 &>/dev/null
			if [[ $? -eq 0 ]]; then
				if [[ ${ssprotocol_param} -ge 1 ]] && [[ ${ssprotocol_param} -le 99999 ]]; then
					echo && echo ${Separator_1} && echo -e "	${Word_number_of_devices} : ${Green_font_prefix}${ssprotocol_param}${Font_color_suffix}" && echo ${Separator_1} && echo
					break
				else
					echo "${Errpr_input_num_error}"
				fi
			else
				echo "${Errpr_input_num_error}"
			fi
			done
		else
			echo -e "${Error_limit_the_number_of_devices_1}" && exit 1
		fi
	else
		echo -e "${Error_limit_the_number_of_devices_2}" && exit 1
	fi
	set_config_protocol_param
	RestartSSR
	echo -e "${Info_limit_the_number_of_devices}"
}
Speed_limit(){
	SSR_install_status
	# 设置单线程限速
	while true
	do
	echo
	echo -e "${Info_input_single_threaded_speed_limit}"
	echo -e "${Prompt_input_single_threaded_speed_limit}"
	stty erase '^H' && read -p "(${Word_default}: ${Word_unlimited}):" ssspeed_limit_per_con
	[[ -z "$ssspeed_limit_per_con" ]] && ssspeed_limit_per_con=0 && break
	expr ${ssspeed_limit_per_con} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_con} -ge 1 ]] && [[ ${ssspeed_limit_per_con} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	${Word_single_threaded_speed_limit} : ${Green_font_prefix}${ssspeed_limit_per_con} KB/S ${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo "${Errpr_input_num_error}"
		fi
	else
		echo "${Errpr_input_num_error}"
	fi
	done
	# 设置端口总限速
	while true
	do
	echo
	echo -e "${Info_total_port_speed_limit}"
	echo -e "${Prompt_total_port_speed_limit}"
	stty erase '^H' && read -p "(${Word_default}: ${Word_unlimited}):" ssspeed_limit_per_user
	[[ -z "$ssspeed_limit_per_user" ]] && ssspeed_limit_per_user=0 && break
	expr ${ssspeed_limit_per_user} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${ssspeed_limit_per_user} -ge 1 ]] && [[ ${ssspeed_limit_per_user} -le 99999 ]]; then
			echo && echo ${Separator_1} && echo -e "	${Word_port_total_speed_limit} : ${Green_font_prefix}${ssspeed_limit_per_user} KB/S ${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo "${Errpr_input_num_error}"
		fi
	else
		echo "${Errpr_input_num_error}"
	fi
	done
	getUser
	set_config_speed_limit_per
	RestartSSR
	echo -e "${Info_port_speed_limit}"
}
Switch_language(){
	if [[ ! -e "${PWD}/lang_en" ]]; then
		echo -e "${Prompt_switch_language_english}"
		echo && echo -e "${Info_switch_language_english}"
		stty erase '^H' && read -p "(${Word_default}: ${Word_cancel}):" unyn
		[[ -z ${unyn} ]] && echo "${Word_canceled}" && exit 1
		if [[ ${unyn} == [Yy] ]]; then
			echo "lang_en" > "${PWD}/lang_en"
			echo -e "${Info_switch_language_1}" && exit 1
		fi
	else
		echo -e "${Prompt_switch_language_chinese}"
		echo && echo -e "${Info_switch_language_chinese}"
		stty erase '^H' && read -p "(${Word_default}: ${Word_cancel}):" unyn
		[[ -z ${unyn} ]] && echo "${Word_canceled}" && exit 1
		if [[ ${unyn} == [Yy] ]]; then
			rm -rf "${PWD}/lang_en"
			echo -e "${Info_switch_language_1}" && exit 1
		fi
	fi
}
Language
#菜单判断
echo
echo && echo "${Menu_prompt_1}" && echo
echo -e "${Menu_options}"
check_sys
[[ ${release} != "centos" ]] && echo -e "${Menu_options_bbr}"
echo -e "${Menu_options_other}"
if [[ -e $config_user_file ]]; then
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [[ ! -z "${PID}" ]]; then
		echo -e "${Menu_status_1}"
	else
		echo -e "${Menu_status_2}"
	fi
	now_mode_1=`jq '.port_password' ${config_user_file}`
	if [[ "${now_mode_1}" = "null" ]]; then
		echo -e "${Menu_mode_1}"
	else
		echo -e "${Menu_mode_2}"
	fi
else
	echo -e "${Menu_status_3}"
fi
echo
stty erase '^H' && read -p "${Menu_prompt_2}" num

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
	0)
	Switch_language
	;;
	*)
	echo "${Menu_prompt_3}"
	;;
esac