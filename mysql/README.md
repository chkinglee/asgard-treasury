# install_mysql.sh

支持在centos上安装mysql

需要手动下载mysql源码包，手动修改shell脚本中的mysql源码包文件名，否则文件对不上

需要与源码包同目录

usage：

sh install_mysql.sh <target_path> <port>


explain:

target_path: 最终生成的mysql免安装目录的绝对路径

port: 要部署mysql-server的port，主要会影响配置文件的设定


case:

sh install_mysql.sh /root/mysql_3306 3306


warning:

1. 使用root权限，更方便，因为会预先检查系统中依赖工具的安装情况，如果缺少工具，会用yum直接安装

2. target_path 一定要是个安全目录，脚本中会rm -rf 

