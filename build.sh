#!/bin/bash

docker-compose down -v
rm -rf ./master/data/*
rm -rf ./replica_one/data/*
rm -rf ./replica_two/data/*
docker-compose build
docker-compose up -d

# setting up master
until docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done

priv_stmt='CREATE USER "mydb_replica1"@"%" IDENTIFIED BY "mydb_replica_pwd"; GRANT REPLICATION SLAVE ON *.* TO "mydb_replica1"@"%"; FLUSH PRIVILEGES;'
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$priv_stmt'"

priv_stmt='CREATE USER "mydb_replica2"@"%" IDENTIFIED BY "mydb_replica_pwd"; GRANT REPLICATION SLAVE ON *.* TO "mydb_replica2"@"%"; FLUSH PRIVILEGES;'
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$priv_stmt'"


# setting up first replica
until docker-compose exec mysql_replica_one sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_replica_one database connection..."
    sleep 4
done


MS_STATUS=`docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='mydb_replica1',MASTER_PASSWORD='mydb_replica_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'
docker exec mysql_replica_one sh -c "$start_slave_cmd"

docker exec mysql_replica_one sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"


# setting up second replica
until docker-compose exec mysql_replica_two sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_replica_two database connection..."
    sleep 4
done


start_slave_stmt="CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='mydb_replica2',MASTER_PASSWORD='mydb_replica_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'
docker exec mysql_replica_two sh -c "$start_slave_cmd"

docker exec mysql_replica_two sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"
