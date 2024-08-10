#!/bin/bash

#版权©www.anstaryun.com

echo "正在与云端对比"
local_file="/root/linux.sh"
remote_file_url="http://linux.anstaryun.com/linux.sh"
temp_remote_file="/root/remote_file.sh"
curl -o "$temp_remote_file" "$remote_file_url"
if diff "$local_file" "$temp_remote_file" > /dev/null; then
    echo -e "\033[32m当前脚本为最新版\033[0m"
else
    # 如果文件不同，下载新的脚本文件并设置执行权限
    echo "本地文件未更新，正在更新..."
    curl -O "$remote_file_url" && chmod +x linux.sh
    #进度条
    echo -e "\033[32m文件已更新并设置执行权限\033[0m"
fi
rm "$temp_remote_file"

# 获取系统运行时间
uptime=$(uptime -p)
uptime_cleaned=$(echo $uptime | sed 's/week/周/; s/hours/小时/; s/minutes/分钟/')

# 获取服务器IP地址
server_ip=$(hostname -I)


#版权©www.anstaryun.com
#====================== 主菜单======================
main_menu() {
    local choice
    while true; do
        echo "Linux工具箱脚本"    
        echo "CPU负载:  $(top -b -n 1 | grep "Cpu(s)" | awk '{print $2}')%" 
        echo "内存使用情况: $(free -m | awk 'NR==2{printf "%.2f%%\n", $3*100/$2}')"
        echo "服务器IP地址: $server_ip"
        echo "服务器运行时间: $uptime_cleaned"
        echo "此脚本由-暗星云[www.anstaryun.com]维护"
        echo "  1. 运维面板安装菜单"
        echo "  2. 硬盘/内存类操作菜单"
        echo "  3. 系统类操作菜单"
        echo "  4. 网络类操作菜单"
        echo "  x. 退出"
        read -p "请输入你的选择（1-x）：" choice
        case $choice in
            1) show_menu1;;
            2) show_menu2;;
            3) show_menu3;;
            4) show_menu4;; 
            x) exit 0;;
            *) echo "无效的输入，请选择1-x。";;
        esac
    done
}

#版权©www.anstaryun.com
# ======================运维面板安装菜单======================
show_menu1() {
    local choice
    while true; do
        echo "===Linux运维面板安装==="
        echo "  1. 宝塔"
        echo "  2. 1Panel"
        echo "  3. AWH"
        echo "  x. 返回主菜单"
        read -p "请输入你的选择（1-3）：" choice
        case $choice in
            1) install_baota;;
            2) install_1panel;;
            3) install_awh;;
            x) main_menu;;
            *) echo "无效的输入，请选择1-3或x。";;
        esac
    done
}

# 安装宝塔面板
install_baota() {
    local baota_url
    case $(grep -ih "buntu" /etc/*release 2>/dev/null || echo centos) in
        "ubuntu"|"debian")
            baota_url="https://download.bt.cn/install/install-ubuntu_6.0.sh"
            ;;
        "centos")
            baota_url="https://download.bt.cn/install/install_6.0.sh"
            ;;
        *)
            echo "不支持的操作系统。"
            return 1
            ;;
    esac
    echo "正在下载对应系统宝塔面板安装脚本..."
    wget -O install.sh "$baota_url" && bash install.sh "ed8484bec"
}

# 安装1Panel面板
install_1panel() {
    echo "正在下载1Panel安装脚本..."
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
}

# 安装AWH面板
install_awh() {
    local awh_url="https://dl.amh.sh/amh.sh"
    echo "正在下载AWH安装脚本..."
    wget "$awh_url" -O amh.sh && bash amh.sh && rm -f amh.sh
}

#版权©www.anstaryun.com
#====================== 硬盘/内存类操作菜单======================
show_menu2() {
    local choice
    while true; do
        echo "===硬盘/内存类操作菜单==="
        echo "  1. 虚拟内存添加"
        echo "  2. 虚拟内存卸载"
        echo "  3. 挂载数据盘"
        echo "  4. 卸载数据盘"
        echo "  5. 修复硬盘分区坏块"
        echo "  6. 查看硬盘分区信息"
        echo "  x. 返回主菜单"
        read -p "请输入你的选择（1-6）：" choice
        case $choice in
            1) set_swap;;
            2) unset_swap;;  # 修复了未调用的函数
            3) mount_data_disk;;
            4) umount_data_disk;;
            5) fix_disk_bad_blocks;;
            6) show_disk_info;;
            x) main_menu;;
            *) echo "无效的输入，请选择1-6或x。";;
        esac
    done
}

# 虚拟内存添加
set_swap() {
    local swap_size
    read -p "请输入虚拟内存大小（单位：GB）: " swap_size
    if ! [[ $swap_size =~ ^[0-9]+$ ]]; then
        echo "无效的输入，请输入一个有效的数字"
        return
    fi

    execute_command "fallocate -l ${swap_size}G /swapfile"
    execute_command "chmod 600 /swapfile"
    execute_command "mkswap /swapfile"
    execute_command "swapon /swapfile"
    execute_command "echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab"
    echo "虚拟内存已设置为 ${swap_size}GB。"
}

# 卸载虚拟内存
unset_swap() {
    execute_command "swapoff /swapfile"
    execute_command "rm -f /swapfile"
    execute_command "sed -i '/swapfile/d' /etc/fstab"
    echo "虚拟内存已卸载。"
    }

    #版权©www.anstaryun.com

# 挂载数据盘
mount_data_disk() {
    local disk_device=${disk_device:-"/dev/vdb1"}
    local mount_point=${mount_point:-"/data"}

    execute_command "mkdir -p '$mount_point'"
    execute_command "mount '$disk_device' '$mount_point'"
    execute_command "echo '$disk_device $mount_point ext4 defaults 0 2' | sudo tee -a /etc/fstab"
    echo "数据盘 $disk_device 已挂载到 $mount_point。"
}

# 卸载数据盘
umount_data_disk() {
    local mount_point=${mount_point:-"/data"}
    execute_command "umount '$mount_point'"
    echo "数据盘 $mount_point 已卸载。"
}

# 修复硬盘分区坏块
fix_disk_bad_blocks() {
    read -p "请输入要修复坏块的硬盘分区（例如：/dev/home）：" partition
    echo "开始修复硬盘分区坏块..."
    xfs_repair $partition -L
    echo "修复完成！"
}

# 执行命令并检查错误
execute_command() {
    echo "执行命令: \\$1"
    bash -c "\\$1"
    if [ $? -ne 0 ]; then
        echo "命令执行失败，请检查您的输入或网络连接。"
        return 1
    fi
}

#查看硬盘分区信息
show_disk_info() {
    fdisk -l
}

#版权©www.anstaryun.com
#======================系统类操作菜单======================
show_menu3() {
    local choice
    while true; do
        echo "===系统类操作菜单==="
        echo "  1. 更新源"
        echo "  2. 同步上海时间"
        echo "  3. 修改主机名"
        echo "  4. 修改ssh密码"
        echo "  5. 关闭 SELinux"
        echo "  6. 修改服务器DNS"
        echo "  7. 查看服务器信息"
        echo "  8. 更新Centos8 stream"
        echo "  9. 查看ssh登录记录"
        echo "  x. 返回主菜单"
        read -p "请输入你的选择（1-9）：" choice
        case $choice in
            1) set_aliyung_source;;
            2) sync_shanghai_time;;
            3) change_hostname;;
            4) change_password;;
            5) close_selinux;;
            6) change_dns;;
            7) show_system_info;;
            8) update_centos8_stream;;
            9) show_ssh_login_records;;
            x) main_menu;;
            *) echo "无效的输入，请选择1-9或x。";;
        esac
    done
}

# 自动检测系统并设置阿里云镜像源
set_aliyung_source() {
    local os_type
    if [[ -f /etc/os-release ]]; then
        os_type=$(. /etc/os-release && echo "$ID" | tr '[:upper:]' '[:lower:]')
    else
        echo "无法检测到操作系统类型。"
        return
    fi

    local mirror="mirrors.aliyun.com"
    case $os_type in
        "ubuntu"|"debian")
            echo "检测到基于Debian的系统，设置阿里云Ubuntu镜像源..."
            execute_command "sed -i 's@http://[^ ]*archive.ubuntu.com@http://$mirror@' /etc/apt/sources.list /etc/apt/sources.list.d/*"
            ;;
        "centos")
            local centos_version=$(grep -Eo '[0-9]+[.][0-9]+' /etc/centos-release | cut -d'.' -f1)
            echo "检测到CentOS $centos_version 系统，设置阿里云CentOS镜像源..."
            execute_command "sed -i 's@http://[^ ]*mirror.centos.org@http://$mirror@' /etc/yum.repos.d/*.repo"
            ;;
        *)
            echo "不支持的操作系统。"
            return
            ;;
    esac

    if [[ $os_type == "ubuntu" ]] || [[ $os_type == "debian" ]]; then
        execute_command "apt-get update"
    elif [[ $os_type == "centos" ]]; then
        execute_command "yum clean all && yum makecache"
    fi
    echo "阿里云镜像源设置完成。"
    return_to_main
}

# 执行命令并检查错误
execute_command() {
    echo "执行命令: \$1"
    bash -c "\$1"
    if [ $? -ne 0 ]; then
        echo "命令执行失败，请检查您的输入或网络连接。"
        return 1
    fi
}

return_to_main() {
    echo "按任意键返回主菜单..."
    read -r
    main_menu
}

# 同步上海时间函数
sync_shanghai_time() {
    install_ntpdate
    echo "正在同步上海时间..."
    sudo timedatectl set-timezone Asia/Shanghai
    sudo ntpdate cn.pool.ntp.org
    echo "时间同步完成。"
}

# 修改主机名的函数
change_hostname() {
    local new_hostname
    read -p "请输入新的主机名：" new_hostname
    if [ -n "$new_hostname" ]; then
        sudo hostnamectl set-hostname "$new_hostname"
        if [ $? -eq 0 ]; then
            echo "主机名已成功修改为：$new_hostname"
        else
            echo "修改主机名失败，请检查输入是否有误。"
        fi
    else
        echo "输入的主机名不能为空。"
    fi
}

#修改ssh密码
change_password() {
    local old_password
    local new_password
    local confirm_password

    while true; do
        read -s -p "请输入当前密码：" old_password
        echo
        read -s -p "请输入新密码：" new_password
        echo
        read -s -p "请再次输入新密码：" confirm_password
        echo

        if [ "$new_password" != "$confirm_password" ]; then
            echo "两次输入的新密码不一致，请重新输入。"
        else
            break
        fi
    done

    # 修改密码
    echo "正在修改密码..."
    sudo usermod -p "$(openssl passwd -1 "$new_password")" "$(whoami)"
    if [ $? -eq 0 ]; then
        echo "密码修改成功。"
    else
        echo "密码修改失败，请检查输入是否有误。"
    fi
    #打印密码
    echo "新密码为：$new_password"
}

#关闭 SELinux
close_selinux() {
    sestatus=$(sestatus | awk '{print \$3}')

    if [[ $sestatus == "enabled" ]]; then
        echo "当前 SELinux 状态为已启用。"
        echo "正在关闭 SELinux..."
        setenforce 0
        if [[ $(sestatus | awk '{print \$3}') == "disabled" ]]; then
            echo "SELinux 已成功禁用。"
        else
            echo "无法禁用 SELinux。"
        fi
    else
        echo "当前 SELinux 状态为已禁用。"
    fi
}

#修改服务器DNS
change_dns() {
    local dns_server
    read -p "请输入新的DNS服务器地址（多个地址用空格分隔）：" dns_server
    if [ -n "$dns_server" ]; then
        sudo sed -i "s/nameserver .*/nameserver $dns_server/" /etc/resolv.conf
        if [ $? -eq 0 ]; then
            echo "DNS服务器地址已成功修改为：$dns_server"
        else
            echo "修改DNS服务器地址失败，请检查输入是否有误。"
        fi
    else
        echo "输入的DNS服务器地址不能为空。"
    fi
    echo "当前DNS服务器地址为：$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}')"
}

#更新Centos8 stream
update_centos8_stream() {
    if [ "$(cat /etc/os-release | grep "ID=centos" | grep "VERSION_ID=8" | wc -l)" -eq 0 ]; then
        echo "当前操作系统不是CentOS 8，无法执行更新操作。"
        return
    fi
    echo "正在更新YUM仓库源到阿里云镜像..."
    sudo sed -i 's@mirrorlist=http://mirrorlist.centos.org@#mirrorlist=http://mirrorlist.centos.org@g' /etc/yum.repos.d/CentOS-*
    sudo sed -i 's@#baseurl=http://mirror.centos.org@baseurl=http://mirrors.aliyun.com@g' /etc/yum.repos.d/CentOS-*
    sudo yum clean all
    sudo yum makecache
    echo "YUM仓库源已更新到阿里云镜像。"
}

#查看ssh登录记录
show_ssh_login_records() {
    echo "===SSH登录记录==="
    last -i
}

# 查看服务器信息
show_system_info() {
    echo "=== 服务器配置信息 ==="
    local cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    echo "CPU核心数: $cpu_cores"
    local cpu_freq=$(grep 'cpu MHz' /proc/cpuinfo | awk '{print $4}' | head -1)
    echo "CPU频率: ${cpu_freq} MHz"
    local cpu_model=$(grep 'model name' /proc/cpuinfo | awk -F: '{print $2}' | head -1)
    echo "CPU型号: $cpu_model"
    
    local virtualization_type
    if [ -f /proc/xen/capabilities ]; then
        virtualization_type="Xen"
    elif grep -q "hypervisor" /proc/cpuinfo; then
        virtualization_type="KVM"
    else
        virtualization_type="物理机"
    fi
    echo "服务器虚拟化类型: $virtualization_type"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "系统版本: $PRETTY_NAME"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "系统版本: $DISTRIB_DESCRIPTION"
    else
        echo "无法识别的系统类型"
    fi
    
    local mem_size=$(free -m | awk '/^Mem:/{print $2}')
    echo "内存大小: $mem_size MB"
    
    local disk_size=$(df -h | awk '$6 == "/" {print $2}')
    echo "磁盘大小: $disk_size"
    
    local swap_size=$(free -m | awk '/^Swap:/{print $2}')
    echo "虚拟内存大小: $swap_size MB"
    
    local dns_servers=$(cat /etc/resolv.conf | grep '^nameserver' | awk '{print $2}' | tr '\n' ' ')
    echo "DNS服务器地址: $dns_servers"
}

# ======================网络类操作菜单======================
show_menu4() {
    local choice
    while true; do
        echo "===网络类操作菜单==="
        echo "  1. 查看网卡信息"
        echo "  2. 重启网卡"
        echo "  3. 开启/关闭ping"
        echo "  4. 绑定新增ip"
        echo "  5. 开启/关闭IP映射"
        echo "  6. 查看占用的端口"
        echo "  x. 返回上一级"
        read -p "请输入你的选择（1-x）：" choice
        case $choice in
            1) show_network_card;;
            2) reboot_network_card;;
            3) toggle_ping;;
            4) bind_new_ip;;
            5) toggle_ip_mapping;;
            6) check_port_usage;;
            x) return;;
            *) echo "无效的输入，请选择1-x。";;
        esac
    done
}

#查看网卡信息
show_network_card() {
    echo "===网卡信息==="
    ip addr show
}

#重启网卡
reboot_network_card() {
    echo "正在重启网卡..."
    sudo ifconfig eth0 down
    sudo ifconfig eth0 up
    if [ $? -eq 0 ]; then
        echo "网卡重启成功。"
    else
        echo "网卡重启失败。"
    fi
}

#开启/关闭ping
toggle_ping() {
    local choice
    while true; do
        echo "===开启/关闭ping==="
        echo "  1. 开启ping"
        echo "  2. 关闭ping"
        echo "  x. 退出"
        read -p "请输入你的选择（1-x）：" choice
        case $choice in
            1) enable_ping;;
            2) disable_ping;;
            x) exit 0;;
            *) echo "无效的输入，请选择1-x。";;
        esac
    done
}

enable_ping() {
    echo "正在开启ping..."
    sudo sysctl -w net.ipv4.ping_group_range="0 2147483647"
    if [ $? -eq 0 ]; then
        echo "ping已开启。"
    else
        echo "ping开启失败。"
    fi
}

disable_ping() {
    echo "正在关闭ping..."
    sudo sysctl -w net.ipv4.ping_group_range="-1 -1"
    if [ $? -eq 0 ]; then
        echo "ping已关闭。"
    else
        echo "ping关闭失败。"
    fi
}

#绑定新增ip
bind_new_ip() {
    local new_ip
    read -p "请输入新的IP地址：" new_ip
    if [ -n "$new_ip" ]; then
        sudo ip addr add $new_ip dev eth0
        if [ $? -eq 0 ]; then
            echo "新的IP地址绑定成功。"
        else
            echo "新的IP地址绑定失败，请检查输入是否有误。"
        fi
    else
        echo "输入的新IP地址不能为空。"
    fi
    echo "当前绑定的IP地址为：$(ip addr show eth0 | grep "inet " | awk '{print \$2}')"
}

#开启/关闭IP映射
toggle_ip_mapping() {
    local choice
    while true; do
        echo "===开启/关闭IP映射==="
        echo "  1. 开启IP映射"
        echo "  2. 关闭IP映射"
        echo "  x. 返回上一级"
        read -p "请输入你的选择（1-x）：" choice
        case $choice in
            1) enable_ip_mapping;;
            2) disable_ip_mapping;;
            x) return;;
            *) echo "无效的输入，请选择1-x。";;
        esac
    done
}

enable_ip_mapping() {
    read -p "请输入VPS的IP地址: " vps_ip
    read -p "请输入VPS上要转发的端口: " vps_port
    read -p "请输入独立服务器的IP地址: " server_ip
    read -p "请输入独立服务器上要映射到的端口: " server_port

    if [ -n "$vps_ip" ] && [ -n "$vps_port" ] && [ -n "$server_ip" ] && [ -n "$server_port" ]; then
        sudo iptables -t nat -A PREROUTING -p tcp -d $vps_ip --dport $vps_port -j DNAT --to-destination $server_ip:$server_port
        if [ $? -eq 0 ]; then
            echo "IP映射已开启。"
        else
            echo "IP映射开启失败。"
        fi
    else
        echo "输入的IP地址或端口不能为空。"
    fi
}

#关闭IP映射
disable_ip_mapping() {
    sudo iptables -t nat -F
    echo "IP映射已成功关闭"
}

# 检查端口占用情况
check_port_usage() {
    # 检测是否有安装netstat
    if ! command -v netstat &> /dev/null; then
        echo "netstat 未安装"
        if command -v apt &> /dev/null; then
            sudo apt-get update -q --progress=dot && sudo apt-get install -y -q --progress=dot net-tools
        elif command -v yum &> /dev/null; then
            sudo yum install -y --quiet net-tools
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y --quiet net-tools
        else
            echo "无法识别的包管理器，请手动安装 net-tools 包。"
            return
        fi
    fi

    # 输出监听端口
    netstat -tulpn | grep LISTEN
}

#版权©www.anstaryun.com

# 程序入口点
main_menu