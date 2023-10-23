#!/bin/sh

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "
  ${green}XrayR 后端管理脚本，${plain}${red}不适用于docker${plain}
--- https://github.com/mingge9527/New-XrayR-Alpine ---
  ${green}0.${plain} 修改配置
————————————————
  ${green}1.${plain} 安装 XrayR
  ${green}2.${plain} 卸载 XrayR
————————————————
  ${green}3.${plain} 启动 XrayR
  ${green}4.${plain} 停止 XrayR
  ${green}5.${plain} 重启 XrayR
  ${green}6.${plain} 查看 XrayR 状态
  ${green}7.${plain} 查看 XrayR 日志
————————————————
  ${green}8.${plain} 设置 XrayR 开机自启
  ${green}9.${plain} 取消 XrayR 开机自启
————————————————
 ${green}10.${plain} 生成 XrayR 配置
 "
# 检查是否安装XrayR
if [ -d "/etc/XrayR" ]; then
    # 检查XrayR运行状态
    xrayr_service_status=$(rc-service XrayR status 2>&1)
    
    if echo "$xrayr_service_status" | grep -q "started"; then
        xray_status="${green}已运行${plain}"
    elif echo "$xrayr_service_status" | grep -q "stopped"; then
        xray_status="${red}未运行${plain}"
    elif echo "$xrayr_service_status" | grep -q "crashed"; then
        xray_status="${yellow}已崩溃${plain}"
    else
        xray_status="$xrayr_service_status"
    fi

    # 检查是否开机自启
    if rc-update show default | grep -q "XrayR | default" ; then
        auto_start="${green}是${plain}"
    else
        auto_start="${red}否${plain}"
    fi
else
    xray_status="${red}未安装${plain}"
    auto_start=""
fi

echo -e "XrayR状态: $xray_status"
if [ -n "$auto_start" ]; then
    echo -e "是否开机自启: ${auto_start}"
fi

# 检查脚本是否以root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo ""
    echo -e "${red}错误:${plain} 必须使用root用户运行此脚本！\n"
    exit 1
fi

# 定义安装XrayR的函数
install_xrayr() {
    read -p "输入指定版本(默认最新版): " version_input

    if [ -z "$version_input" ]; then
        # 用户按下回车，获取最新版本
        last_version=$(curl -Ls "https://api.github.com/repos/XrayR-project/XrayR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        # 用户输入了版本号，使用用户指定的版本
        last_version="$version_input"
    fi

    if [ -z "$last_version" ]; then
        echo -e "${red}检测 XrayR 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 XrayR 版本安装${plain}"
        exit 1
    fi

    echo -e "${yellow}开始安装${plain}"
    
    arch=$(arch)

    if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
        arch="64"
    elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
        arch="arm64-v8a"
    elif [[ $arch == "i386" || $arch == "i486" || $arch == "i586" || $arch == "i686" ]]; then
        arch="32"
    elif [[ $arch == "s390x" ]]; then
        arch="s390x"
    else
        arch="32"
        echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
    fi

    echo "架构: ${arch}"
    
    # 检查所需软件包是否已安装
    if ! command -v sudo >/dev/null 2>&1; then
        apk add sudo
    fi
    if ! command -v wget >/dev/null 2>&1; then
        apk add wget
    fi
    if ! command -v curl >/dev/null 2>&1; then
        apk add curl
    fi
    if ! command -v unzip >/dev/null 2>&1; then
        apk add unzip
    fi

    # 检查 /etc/XrayR/XrayR 文件是否存在
    if [ -f "/etc/XrayR/XrayR" ]; then
        echo -e "${red}XrayR已安装，请不要重复安装${plain}"
        exit 1
    fi

    # 检查系统是否为Alpine
    if ! grep -qi "Alpine" /etc/os-release; then
        echo "${red}该脚本仅支持Alpine系统${plain}"
        exit 1
    fi

    # 切换到 /etc 目录
    cd /etc

    # 开始下载XrayR
    if [ -d "/etc/XrayR" ]; then
        rm -rf /etc/XrayR
    fi
    mkdir XrayR
    cd XrayR
    wget -N --no-check-certificate "https://github.com/XrayR-project/XrayR/releases/download/${last_version}/XrayR-linux-${arch}.zip"
    unzip XrayR-linux-${arch}.zip
    chmod 777 XrayR
    echo "正在写入rc-service……"
    cd /etc/init.d
    rc-service XrayR stop
    rc-update del XrayR default
    rm XrayR
    wget https://raw.githubusercontent.com/mingge9527/New-XrayR-Alpine/main/XrayR
    chmod 777 XrayR
    rc-update add XrayR default

    if [ $? -eq 0 ]; then
        echo -e "${green}XrayR已安装完成，请先配置好配置文件后再启动${plain}"
    else
        echo -e "${red}XrayR安装失败${plain}"
    fi

    exit 0
}

# 根据用户选择执行相应操作
echo
read -p "请输入选择 [0-10]: " option

case "$option" in
    "0")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
        echo
        echo -e "请选择编辑器:"
        echo -e "${green}1.${plain} vi"
        echo -e "${green}2.${plain} nano"
        read -p "请输入选择 [1-2]: " choice

        if [ "$choice" = "1" ]; then
            vi /etc/XrayR/config.yml
        elif [ "$choice" = "2" ]; then
            if ! command -v nano >/dev/null 2>&1; then
                apk add nano
            fi
            nano /etc/XrayR/config.yml
        else
            echo -e "${red}请输入正确的数字 [1-2]${plain}"
        fi
        ;;
    "1")
        install_xrayr
        ;;
    "2")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi

        # 确认卸载
        read -p "确定要卸载 XrayR 吗?[y/n]: " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            cd /etc/init.d
            rc-service XrayR stop
            rc-update del XrayR default
            rm XrayR
            rm -rf /etc/XrayR

            echo -e "卸载成功，如果你想删除此脚本，则退出脚本后运行 ${green}rm /usr/bin/xrayr${plain} 进行删除"
        else
            echo "取消卸载"
        fi
        exit 0
        ;;
    "3")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi

        if rc-service XrayR status | grep -q "* status: started"; then
            echo -e "${green}XrayR已运行，无需再次启动，如需重启请选择重启${plain}"
            exit 1
        fi

        rc-service XrayR start

        echo -e "${green}XrayR 启动成功${plain}"
        echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
        xrayr
        ;;
    "4")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
        
        rc-service XrayR stop

        echo -e "${green}XrayR 停止成功${plain}"
        echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
        xrayr
        ;;
    "5")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
    
        rc-service XrayR restart
        
        echo -e "${green}XrayR 重启成功${plain}"
        echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
        xrayr
        ;;
    "6")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
    
        rc-service XrayR status
        echo ""
        tail -n 10 -q /var/log/XrayR.log
        echo ""
        
        echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
        xrayr
        ;;
    "7")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
    
        tail -f /var/log/XrayR.log
        ;;
    "8")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
    
        rc-update add XrayR default
        echo -e "${green}XrayR 设置开机自启成功${plain}"
        echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
        xrayr
        ;;
    "9")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
    
        rc-update del XrayR default
        echo -e "${green}XrayR 取消开机自启成功${plain}"
        echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
        xrayr
        ;;
    "10")
        if [ ! -f "/etc/XrayR/XrayR" ]; then
            echo -e "${red}请先安装XrayR${plain}"
            exit 1
        fi
        
        if [ ! -f "/etc/XrayR/config.yml" ]; then
            echo "XrayR配置文件不存在，你还没有安装XrayR或配置文件丢失！"
            exit 1
        fi
        
        echo "请注意，此为实验性功能，若出问题请手动修改配置文件"
        echo "XrayR默认安装路径为/etc/XrayR"
        echo "面板类型默认设置为V2board，自动进行下一步"
        echo ""
        
        # 设定机场地址
        echo "设定机场地址"
        echo ""
        read -p "请输入你的机场地址:" apihost
        [ -z "${apihost}" ]
        echo "—————————————————"
        echo "您设定的机场网址为 ${green}${apihost}${plain}"
        echo "—————————————————"
        echo ""
        
        
        # 设定API Key
        echo "设定与面板对接的API Key"
        echo ""
        read -p "请输入API Key:" apikey
        [ -z "${apikey}" ]
        echo "—————————————————"
        echo "您设定的API Key为 ${green}${apikey}${plain}"
        echo "—————————————————"
        echo ""
    
        # 设置节点序号
        echo "设定节点序号"
        echo ""
        read -p "请输入V2Board中的节点序号:" node_id
        [ -z "${node_id}" ]
        echo "—————————————————"
        echo "您设定的节点序号为 ${green}${node_id}${plain}"
        echo "—————————————————"
        echo ""

        # 选择协议
        echo "选择节点类型(默认Shadowsocks)"
        echo ""
        read -p "请输入你使用的协议(V2ray, Shadowsocks, Trojan等):" node_type
        [ -z "${node_type}" ]
    
        # 如果不输入默认为Shadowsocks
        if [ ! $node_type ]; then 
        node_type="Shadowsocks"
        fi

        echo "—————————————————"
        echo "您选择的协议为 ${green}${node_type}${plain}"
        echo "—————————————————"
        echo ""

        # 输入域名（Trojan证书申请）
        echo "输入你的域名（Trojan证书申请）"
        echo ""
        read -p "请输入你的域名(node.v2board.com)如无需证书请直接回车:" node_domain
        [ -z "${green}${node_domain}${plain}" ]

        # 如果不输入默认为node1.v2board.com
        if [ ! $node_domain ]; then 
        node_domain="node.v2board.com"
        fi

        # 写入配置文件
        echo "${yellow}正在尝试写入配置文件...${plain}"
        sed -i "s/PanelType:.*/PanelType: \"V2board\"/g" /etc/XrayR/config.yml
        sed -i "s,ApiHost:.*,ApiHost: \"${apihost}\",g" /etc/XrayR/config.yml
        sed -i "s/ApiKey:.*/ApiKey: ${apikey}/g" /etc/XrayR/config.yml
        sed -i "s/NodeID:.*/NodeID: ${node_id}/g" /etc/XrayR/config.yml
        sed -i "s/NodeType:.*/NodeType: ${node_type}/g" /etc/XrayR/config.yml
        sed -i "s/CertDomain:.*/CertDomain: \"${node_domain}\"/g" /etc/XrayR/config.yml
        echo ""
        echo "${yellow}写入完成，正在尝试重启XrayR服务...${plain}"
        echo
        rc-service XrayR restart
        
        echo "${green}XrayR服务已经完成重启，请愉快地享用！${plain}"
        echo
        exit 0
        ;;
    *)
        if [ -n "$option" ]; then
            echo -e "${red}请输入正确的数字 [0-10]${plain}"
        fi
        exit 1
        ;;
esac
