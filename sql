2.1.新建用户
CREATE USER infodba SUPERUSER PASSWORD 'infodba';
CREATE USER replica PASSWORD '123456' REPLICATION;
CREATE USER pgrewind SUPERUSER PASSWORD '123456';
create user TcClusterDB password 'tcclusterdb';

2.2新建表空间
-- infodba_idata   /data01/pgsql/tc/infodba_idata
-- infodba_ilog    /data01/pgsql/tc/infodba_ilog
-- infodba_indx   /data01/pgsql/tc/infodba_index
  --tcclusterdb_idata  /data01/pgsql/tc/tcclusterdb_idata
  mkdir -p /data01/pgsql/tc/infodba_idata
  mkdir -p /data01/pgsql/tc/infodba_ilog
  mkdir -p /data01/pgsql/tc/infodba_index
  mkdir -p /data01/pgsql/tc/tcclusterdb_idata
  

CREATE TABLESPACE infodba_idata LOCATION '/data01/pgsql/tc/infodba_idata';
CREATE TABLESPACE infodba_ilog LOCATION '/data01/pgsql/tc/infodba_ilog';
CREATE TABLESPACE infodba_indx LOCATION '/data01/pgsql/tc/infodba_index';
CREATE TABLESPACE tcclusterdb_idata LOCATION '/data01/pgsql/tc/tcclusterdb_idata';

2.3新建库
CREATE DATABASE tc WITH  owner infodba  encoding 'UTF8' template template0 LC_COLLATE='C'  tablespace infodba_idata ;
create database TcClusterDB with owner TcClusterDB encoding 'UTF8' template template0 lc_collate 'C' tablespace TcClusterDB_idata;
grant all privileges on database TcClusterDB to TcClusterDB;
grant CREATE ON TABLESPACE TcClusterDB_idata to TcClusterDB;
grant all privileges on database tc to infodba;
grant CREATE ON TABLESPACE infodba_idata to infodba;

SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_activity.query AS blocked_query,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.query AS blocking_query
FROM
  pg_catalog.pg_locks blocked_locks
  JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
  JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
  JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE
  blocked_locks.granted AND NOT blocking_locks.granted;

SELECT
  pg_stat_activity.pid AS pid,
  pg_stat_activity.query AS query,
  pg_locks.mode AS lock_mode,
  pg_locks.granted AS lock_granted,
  pg_locks.relation::regclass AS lock_relation
FROM
  pg_stat_activity
  JOIN pg_locks ON pg_stat_activity.pid = pg_locks.pid
WHERE
  pg_locks.locktype = 'relation'
  AND pg_locks.granted = false;

查看锁和等待信息

select activity.pid,activity.usename,activity.wait_event_type,activity.wait_event,activity.query, 
blocking.pid as blocking_pid, blocking.query as blocking_query 
from pg_stat_activity as activity, pg_stat_activity as blocking
where blocking.pid=any(pg_blocking_pids(activity.pid));
