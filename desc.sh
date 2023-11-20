#!/bin/bash

# 数据文件目录
PGDATA='/data01/pgsql'
# 主库IP
IP_ADDR1='192.168.1.20'
# 备库IP
IP_ADDR2='192.168.1.22'
#根据实际情况写主库备库IP前缀
IP_PREFIX="192.168.1"
# 复制槽名称
PG_SLOT1='pg20'
PG_SLOT2='pg22'
# rewind用户密码
USER='pgrewind'
PASSWORD='123456'
# 数据库名称
DBNAME='postgres'
# PG进程名称
PGBIN='/data01/app/postgresql/bin/postgres'
IP_ADDR=$(ifconfig | grep -oP "inet ($IP_PREFIX\.[0-9]{1,3})" | awk '{print $2}')

echo "旧主库同步新主库数据"

#postgres=ps -ef | grep $PGBIN | grep -v grep | awk '{print $2}'

if [ IP_ADDR == IP_ADDR1 ]; then
    echo 1
    su - postgres -c "pg_ctl start"
	su - postgres -c "pg_ctl stop"
	su - postgres -c "pg_rewind --target-pgdata=$PGDATA --source-server='host=$IP_ADDR2 user=$USER password=$PASSWORD dbname=$DBNAME' -P"
else
    echo 2
	# echo "遇到pg_rewind: fatal: target server must be shut down cleanly"
	su - postgres -c "pg_ctl stop"
	su - postgres -c "pg_ctl start"
	su - postgres -c "pg_ctl stop"
	su - postgres -c "pg_rewind --target-pgdata=$PGDATA --source-server='host=$IP_ADDR1 user=$USER password=$PASSWORD dbname=$DBNAME' -P"
fi

echo "创建文件standby.signal"
su - postgres -c "touch $PGDATA/standby.signal"

echo "更新postgresql.auto.conf"

PO=$(grep 'primary_conninfo' /data01/pgsql/postgresql.auto.conf)
if [ -z "$PO" ]; then
  echo "primary_conninfo" >> $PGDATA/postgresql.auto.conf
  
fi

if [[ ${IP_ADDR} == $IP_ADDR1 ]];then
   echo 1
   sed -i "s/^primary_conninfo.*/primary_conninfo = 'user=replica password=123456 host=$IP_ADDR2'/" $PGDATA/postgresql.auto.conf
   sed -i "s/^primary_slot_name.*/primary_slot_name = 'pg22'/" $PGDATA/postgresql.auto.conf
else
    echo 2
    sed -i "s/^primary_conninfo.*/primary_conninfo = 'user=replica password=123456 host=$IP_ADDR1'/"   $PGDATA/postgresql.auto.conf
    sed -i "s/^primary_slot_name.*/primary_slot_name = 'pg20'/" $PGDATA/postgresql.auto.conf
fi

echo "启动数据库"
su - postgres -c "pg_ctl start"

echo "备库查看"
su - postgres -c "psql -c 'SELECT * FROM pg_stat_replication;' " >> slave_replication.log

cat slave_replication.log




