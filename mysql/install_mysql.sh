#!/bin/sh
# 一键安装mysql

cur_dir=$(pwd)
case $# in
2)
  target_path=$1
  port=$2
  ;;
*)
  echo "Usage:sh $0 target_path port"
  echo "please give 2 parameters"
  exit 1
  ;;
esac

mysql_tar="mysql-5.6.49.tar.gz"
mysql_src="mysql-5.6.49"


function download_mysql_source_code() {

  wget https://dev.mysql.com/get/Downloads/MySQL-5.6/$mysql_tar
}


function check_system_tools() {
  local dependecy_tools=(make cmake gcc gcc-c++ openssl-devel ncurses-devel)
  local need_install_num=0
  local need_install_tools=()

  echo "检查依赖工具包是否安装 ${dependecy_tools[@]}"

  for tool in ${dependecy_tools[@]}
  do
    count=`yum list installed | grep -w $tool | wc -l`
    if [[ $count -eq 0 ]];then
      need_install_tools[$need_install_num]=$tool
      need_install_num=`expr $need_install_num + 1`
    fi
  done

  if [[ ${#need_install_tools[@]} -ne 0 ]];then
    echo "有待安装的工具：${need_install_tools[@]}"
    if [[ `whoami` != "root" ]];then
      echo "NEED ROOT POWER"
      exit
    else
      yum -y install ${need_install_tools[@]}
    fi
  fi

  echo "检查完成，等待60s"
  sleep 60
}

function log() {
  local epath=$(pwd)
  local timestamp=$(date +%Y%m%d-%H:%M:%S)
  echo "[$timestamp][$epath]$1"
}

function do_cmd() {
  log "[exec] $*   please wait............"
  if [ $debug -eq 1 ]; then
    $@
  else
    $@ >/dev/null 2>&1
  fi
  if [[ $? -ne 0 ]]; then
    log "[fail] $@"
    exit 1
  else
    log "[succ] $@"
  fi
}

check_system_tools
debug=1

if [ ${target_path:0:1} = "." ]; then
  bpath=$(pwd)
  bpath=${bpath}/${target_path}
else
  bpath=$target_path
fi

sec=$(date +%S)
server_id=$(ping -4 -c 1 $(hostname) | head -n 1 | awk '{print $3}' | sed -r 's/[().\s]//g')
server_id="${server_id}${sec}"
server_id=$(($server_id % 4294967295))

tar zxvf $mysql_tar

ps -ef | grep $bpath/ | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1
do_cmd rm -rf $bpath

if [ -d $target_path ]; then
  log "[fail] target path $target_path already exists"
  exit 1
fi
if [ -d $bpath ]; then
  log "[fail] $bpath already exists!"
  exit 1
fi

do_cmd mkdir -p $bpath


function generate_pwd() {
  local MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz~!@%^&*()_+="
  local LENGTH="30"
  local PASS=""
  while [ "${n:=1}" -le "$LENGTH" ]; do
    PASS="$PASS${MATRIX:$(($RANDOM % ${#MATRIX})):1}"
    let n+=1
  done
  echo ""
  exit 0
}

function generate_sql_cnf() {
  local bpath=$1
  local port=$2
  local server_id=$3

  #local root_pwd=$(generate_pwd)
  #local admin_pwd=$(generate_pwd)
  root_pwd="root"
  admin_pwd="admin"

  cat >$bpath/etc/init.sql <<_EOF_
SET SQL_LOG_BIN=0;

-- clear mysql-bin.00000* create by mysql_install_db
-- RESET MASTER;

-- clear dirty users
DELETE FROM mysql.user WHERE user='';
DELETE FROM mysql.db   WHERE user='';
DELETE FROM mysql.user WHERE host LIKE '%-%';
DELETE FROM mysql.db   WHERE host LIKE '%-%';

-- change password for root
UPDATE mysql.user SET password=PASSWORD('${root_pwd}') WHERE user='root';
UPDATE mysql.user SET password=PASSWORD('${admin_pwd}') WHERE user='admin';

-- create admin users
GRANT SELECT,RELOAD,PROCESS,SHOW DATABASES,SUPER,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'admin'@'localhost' IDENTIFIED BY '${admin_pwd}' WITH GRANT OPTION;
GRANT SELECT,RELOAD,PROCESS,SHOW DATABASES,SUPER,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'admin'@'127.0.0.1' IDENTIFIED BY '${admin_pwd}' WITH GRANT OPTION;
GRANT REPLICATION CLIENT,REPLICATION SLAVE ON *.* TO 'mysqlsync'@'' IDENTIFIED BY 'mysqlsync' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '';

-- reset privileges and replication status;
flush privileges;
-- reset master;
reset slave;

_EOF_

  log "generate mysqld.cnf  server-id=$server_id readonly=$readonly"
  cat >$bpath/etc/mysqld.cnf <<_EOF_
[mysqld]
server-id   = ${server_id}
#log-slave-updates
_EOF_

  log "generate user.root.cnf user=root password=$root_pwd"
  cat >$bpath/etc/user.root.cnf <<_EOF_
[client]
user=root
password=$root_pwd
socket=$bpath/tmp/mysql.sock
_EOF_

  log "generate user.admin.cnf user=admin password=$admin_pwd"
  cat >$bpath/etc/user.admin.cnf <<_EOF_
[client]
user=admin
password=$admin_pwd
socket=$bpath/tmp/mysql.sock
_EOF_

  cat >$bpath/etc/my.cnf <<_EOF_
[client]
port                     = ${port}
socket                   = ${bpath}/tmp/mysql.sock

[mysqld]
core-file
!include ${bpath}/etc/mysqld.cnf
port                     = ${port}
socket                   = ${bpath}/tmp/mysql.sock
pid-file                 = ${bpath}/var/mysql.pid
basedir                  = ${bpath}
datadir                  = ${bpath}/var

# tmp dir settings
tmpdir                   = ${bpath}
slave-load-tmpdir        = ${bpath}

#
#language                 = ${bpath}/share/english
#character-sets-dir       = ${bpath}/share/charsets

# skip options
#skip-grant-tables
#skip-name-resolve
#skip-symbolic-links
#skip-external-locking
#skip-slave-start

#sysdate-is-now

# res settings
back_log                 = 50
max_connections          = 1000
max_connect_errors       = 10000
#open_files_limit         = 10240

connect-timeout          = 5
wait-timeout             = 28800
interactive-timeout      = 28800
slave-net-timeout        = 600
net_read_timeout         = 30
net_write_timeout        = 60
net_retry_count          = 10
net_buffer_length        = 16384
max_allowed_packet       = 64M

#
thread_stack             = 192K
thread_cache_size        = 20
thread_concurrency       = 8

# qcache settings
query_cache_type         = 0
query_cache_size         = 32M
#query_cache_size         = 256M
#query_cache_limit        = 2M
#query_cache_min_res_unit = 2K

# default settings
# time zone
default-time-zone        = system
character-set-server     = utf8
default-storage-engine   = InnoDB
#default-storage-engine   = MyISAM

# tmp & heap
tmp_table_size           = 512M
max_heap_table_size      = 512M

log-bin                  = mysql-bin
sync_binlog              = 0
log-bin-index            = mysql-bin.index
log-slave-updates        = 1
binlog-format            = ROW
#relay-log                = relay-log
relay_log_index          = relay-log.index

# warning & error log
log-warnings             = 1
log-error                = ${bpath}/log/mysql.err

# slow query log
long-query-time          = 1
slow_query_log           = 1
slow_query_log_file      = ${bpath}/log/slow.log
#log-queries-not-using-indexes
# general query log
general_log              = 1
general_log_file         = ${bpath}/log/mysql.log
max_binlog_size          = 1G
max_relay_log_size       = 1G

# if use auto-ex, set to 0
relay-log-purge          = 1

# max binlog keeps days
expire_logs_days         = 7

binlog_cache_size        = 1M

# replication
replicate-wild-ignore-table     = mysql.%
replicate-wild-ignore-table     = test.%
# slave_skip_errors=all

key_buffer_size                 = 256M
sort_buffer_size                = 2M
read_buffer_size                = 2M
join_buffer_size                = 8M
read_rnd_buffer_size            = 8M
bulk_insert_buffer_size         = 64M
myisam_sort_buffer_size         = 64M
myisam_max_sort_file_size       = 10G
myisam_repair_threads           = 1
myisam_recover

transaction_isolation           = REPEATABLE-READ

#GTID:
gtid-mode                       = on
enforce-gtid-consistency        = on

#skip-innodb

innodb_file_per_table
innodb_file_format = Barracuda

#innodb_status_file              = 1
#innodb_open_files               = 2048
innodb_buffer_pool_size         = 8G
innodb_data_home_dir            = ${bpath}/var
innodb_data_file_path           = ibdata1:1G:autoextend
innodb_file_io_threads          = 4
innodb_thread_concurrency       = 16
innodb_flush_log_at_trx_commit  = 1

innodb_log_buffer_size          = 8M
innodb_log_file_size            = 1900M
innodb_log_files_in_group       = 2
innodb_log_group_home_dir       = ${bpath}/var

innodb_max_dirty_pages_pct      = 90
innodb_lock_wait_timeout        = 50
#innodb_flush_method            = O_DSYNC
innodb_page_size		= 32K
#innodb-adaptive-hash-index	= 0
innodb_compression_failure_threshold_pct = 0
#autocommit			= 0

[mysqldump]
quick
max_allowed_packet              = 64M

[mysql]
disable-auto-rehash
default-character-set           = utf8
connect-timeout                 = 3

[isamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
_EOF_
}


do_cmd cd ${cur_dir}/${mysql_src}/
do_cmd mkdir -p ./release
do_cmd cd ./release
export CFLAGS="-O3 -g"
export CXXFLAGS="-O3 -g"

cmake .. -DCMAKE_INSTALL_PREFIX=${bpath} \
-DMYSQL_DATADIR=${bpath}/var \
-DINSTALL_MYSQLDATADIR=var \
-DINSTALL_SBINDIR=libexec \
-DINSTALL_LIBDIR=lib/mysql \
-DSYSCONFDIR=${bpath}/etc \
-DMYSQL_UNIX_ADDR=${bpath}/tmp/mysql.sock \
-DINSTALL_PLUGINDIR=lib/plugin \
-DINSTALL_SCRIPTDIR=bin \
-DINSTALL_MYSQLSHAREDIR=share \
-DINSTALL_SUPPORTFILESDIR=share/mysql \
-DCMAKE_C_FLAGS='-O3 -g' \
-DCMAKE_CXX_FLAGS='-O3 -g' \
-DCMAKE_C_FLAGS_RELEASE='-O3 -g' \
-DCMAKE_CXX_FLAGS_RELEASE='-O3 -g' \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_EXTRA_CHARSETS=all \
-DWITH_UNIT_TESTS=0 \
-DWITH_DEBUG=0 \
-DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
-DWITH_INNODB_MEMCACHED=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STORAGE_ENGINE=0 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DENABLED_PROFILING=1 \
-DWITH_ZLIB=bundled \
-DENABLED_LOCAL_INFILE=1

do_cmd make -j8
do_cmd make install

#make clean && make && pwd
do_cmd cd $bpath
if [ ! -d etc ]; then
  do_cmd mkdir etc
fi
if [ ! -d log ]; then
  do_cmd mkdir log
fi
if [ ! -d tmp ]; then
  do_cmd mkdir tmp
fi
if [ ! -d var ]; then
  do_cmd mkdir var
fi

do_cmd generate_sql_cnf $bpath $port $server_id
do_cmd cp -v $bpath/share/mysql/mysql.server $bpath/bin/
do_cmd chmod 644 $bpath/etc/my.cnf 2>/dev/null
do_cmd chmod 644 $bpath/etc/my*.cnf 2>/dev/null
do_cmd chmod 600 $bpath/etc/user.*.cnf 2>/dev/null
do_cmd chmod 700 $bpath/var
do_cmd chmod 755 $bpath/{bin,log,etc,libexec}
do_cmd $bpath/bin/mysql_install_db --defaults-file=$bpath/etc/my.cnf
do_cmd rm -f $bpath/my.cnf
log "[exec] start mysql, please wait ........."
#do_cmd ${bpath}/bin/mysql.server start
do_cmd ${bpath}/bin/mysqld_safe --defaults-file=${bpath}/etc/my.cnf --user="$(whoami)" >/dev/null 2>&1 &
until [ -f $bpath/var/mysql.pid ]; do
  sleep 1
  log "[wait] wait mysql start up"
done
log "[succ] start mysql succeed"
#do_cmd $bpath/bin/mysql --defaults-file=${bpath}/etc/user.root.cnf <$bpath/etc/init.sql
do_cmd $bpath/bin/mysql -uroot <$bpath/etc/init.sql
log "[succ]Bingo (:"
exit 0