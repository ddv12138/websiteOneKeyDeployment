#!/bin/bash
echo -e "\033[5m ------运行此脚本之前，请先前往父级目录执行docker-compose up -d启动数据库，缓存相关环境----- \033[0m"
sleep 1

#必要参数
echo "export XDG_RUNTIME_DIR=\"/run/user/\$UID\"" >> ~/.bashrc
echo "export DBUS_SESSION_BUS_ADDRESS=\"unix:path=\${XDG_RUNTIME_DIR}/bus\"" >> ~/.bashrc
export XDG_RUNTIME_DIR="/run/user/$UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export config_path="${HOME}/.config/systemd/user"
sys_prefix="systemctl --user"
if [ "$USER" == "root" ];then
    sys_prefix="systemctl"
    config_path="/etc/systemd/system"
fi
echo $config_path
#配置文件路径
if [ ! -d ${config_path} ]; then
    mkdir -p ${config_path}
fi

echo -ne "检测源码目录......"
if [ -d "`pwd`/website-source" ]; then
    echo -ne "\033[1;32mSUCCESS\033[0m\n"
else
    echo -ne "\n源码目录不存在，自动拉取源码库\n"
    git clone https://github.com/ddv12138/WebSite-SpringBoot ./website-source
fi
echo -ne "部署定时获取项目更新并构建jar包的定时任务脚本......\n"
echo "#!/bin/bash
set -e
cd `pwd`/website-source
git pull
if [ ! -f \"../GIT_PREVIOUS_SUCCESSFUL_COMMIT\" ]; then
    echo \`git show --stat|grep commit|cut -c8-40\`>../GIT_PREVIOUS_SUCCESSFUL_COMMIT
    echo \"未检测到上次检查记录，初始化最后一次提交为[\$(cat ../GIT_PREVIOUS_SUCCESSFUL_COMMIT)]\"
    exit 0
fi
export GIT_PREVIOUS_SUCCESSFUL_COMMIT=\$(cat ../GIT_PREVIOUS_SUCCESSFUL_COMMIT)
export GIT_COMMIT=\`git show --stat|grep commit|cut -c8-40\`
echo \"GIT_COMMIT=[\$GIT_COMMIT],GIT_PREVIOUS_SUCCESSFUL_COMMIT=[\$GIT_PREVIOUS_SUCCESSFUL_COMMIT]\"
if [ \"\$GIT_PREVIOUS_SUCCESSFUL_COMMIT\" == \"\$GIT_COMMIT\" ];then
    echo \"未检测到更新。退出\"
    exit 0
else
    echo \"检测到更新,开始构建项目\"
    echo \`git show --stat|grep commit|cut -c8-40\`>../GIT_PREVIOUS_SUCCESSFUL_COMMIT
    docker run --rm --name=maven -v /home/uk/.m2:/root/.m2 -v \"`pwd`/website-source:/usr/src/website-source\" -w \"/usr/src/website-source\"  maven mvn -DskipTests=true package
    echo \"构建成功，重启项目\"
    $sys_prefix restart website.service
    exit 0
fi
">website-update-check.sh
#cat website-update-check.sh
chmod +x website-update-check.sh

echo "
[Unit]
Description=website cron
[Service]
ExecStart=/bin/bash `pwd`/website-update-check.sh
[Install]
WantedBy=timers.target
">${config_path}/cron-website.service
#cat ${config_path}/cron-website.service

echo "
[Unit]
Description=website cron 
[Timer]
OnStartupSec=5m
OnUnitInactiveSec=60
AccuracySec=1s
Persistent=true
[Install]
WantedBy=timers.target
">${config_path}/cron-website.timer
#cat ${config_path}/cron-website.timer

read -sp "请输入项目配置项 [jasypt.encryptor.password] 的属性值 > " password
echo ""
read -p "请输入项目端口号,非root用户不能使用1024以下端口 > " port

echo "
[Unit]
Description=WebSite Services
[Service]
Type=simple
ExecStart=/usr/bin/docker run --rm -v \"`pwd`/website-source/target:/usr/src/website-source/target\" -w \"/usr/src/website-source/target\" --network=host --restart=always --name=website -e TZ=\"Asia/Shanghai\" openjdk:8 java -jar TestWeb-1.0-SNAPSHOT.jar --spring.profiles.active=server --jasypt.encryptor.password=${password} --server.port=${port}
ExecStop=/usr/bin/docker stop website
#ExecStart=/usr/bin/java -jar `pwd`/website-source/target/TestWeb-1.0-SNAPSHOT.jar --spring.profiles.active=server --jasypt.encryptor.password=${password} --server.port=${port}
TimeoutStartSec=0
TimeoutStopSec=30
[Install]
WantedBy=mutli-user.target
">${config_path}/website.service
#cat ${config_path}/website.service
$sys_prefix daemon-reload
$sys_prefix enable cron-website.service cron-website.timer website.service
$sys_prefix start cron-website.service cron-website.service
$sys_prefix status cron-website.service cron-website.timer website.service
echo -ne "\033[1;32mSUCCESS\033[0m\n"
echo "项目环境和脚本部署完成，现在可以通过$sys_prefix enable/disable/start/stop/restart website.service来管理服务"
