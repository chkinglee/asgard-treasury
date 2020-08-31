# install_mysql.sh

## comment:

1. 支持在centos上安装mysql

2. 需要手动下载mysql源码包，手动修改shell脚本中的mysql源码包文件名，否则文件对不上

3. 需要与源码包同目录

Note: 脚本中有download_mysql_source_code方法，可自行调用


## usage：

sh install_mysql.sh <target_path> <port>


## explain:

target_path: 最终生成的mysql免安装目录的绝对路径

port: 要部署mysql-server的port，主要会影响配置文件的设定


## case:

sh install_mysql.sh /root/mysql_3306 3306


## warning:

1. 使用root权限，更方便，因为会预先检查系统中依赖工具的安装情况，如果缺少工具，会用yum直接安装

2. target_path 一定要是个安全目录，脚本中会rm -rf 


# 将mysql服务加入开机启动

1. ps 下mysql的进程，进程启动命令形如

```
/bin/sh /root/mysql_3306/bin/mysqld_safe --defaults-file=/root/mysql_3306/etc/my.cnf --user=root
```

2. 到mysql的bin目录下，编辑mysql.server文件，找到start对应的代码，也会发现类似的一行进程启动命令，大致修改一下

```
# 原先的样子
$bindir/mysqld_safe --datadir="$datadir" --pid-file="$mysqld_pid_file_path" $other_args >/dev/null &

# 修改后的样子
$bindir/mysqld_safe --defaults-file=$basedir/etc/my.cnf --user=root >/dev/null &
```

3. 保存后，cp到 /etc/init.d 目录下，并检查是否有可执行权限

4. 添加开机启动

```
chkconfig --add mysql.server
chkconfig mysql.server on

# 可以测试一下服务启停
service mysql.server start
service mysql.server stop
service mysql.server restart
service mysql.server status
```