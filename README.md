# websiteOneKeyDeployment
自用网站环境一键部署相关

## pgData
pgData是postgresql的数据库文件夹，里面内置了一个权限配置，避免初始化时要重新配置

## redis
redis目录存放redis缓存的配置文件，redis服务启动时会自动生效，rdb文件和日志也会相应存放在此目录

## projectSpace
projectSpace目录存放项目相关文件，包括源码目录，构建结果，定时任务脚本以及初始化脚本

***

* 首先在当前目录下使用docker-compose启动pgsql数据库和redis缓存，pg的数据库目录会自动映射到./pgData，redis自动映射到./redis
* 然后cd进入projectSpace目录，执行initWebsiteService.sh脚本，该脚本会自动做以下几件事
    1. 自动拉取源码
    2. 自动检测java环境，没有则安装openjdk8，仅支持yum源安装
    3. 自动在该目录下输出定时任务脚本，并自动添加到crontab定时任务
    4. 自动生成系统systemctl服务并部署，使支持通过systemctl enable/disable/start/stop/restart website.service来管理服务
* 生成的定时任务脚本为website-update-check.sh，该脚本每次运行都会去源码目录下执行git pull，然后检测git log，如果有新的提交，就会使用docker调用maven镜像构建项目然后自动重启，默认每分钟检测一次，每次检测的日志输出会自动保存到/projectSpace/update-check.log
