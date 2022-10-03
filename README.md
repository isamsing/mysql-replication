Docker MySQL replication setup
========================

MySQL 8.0 replication with using Docker. 

## Run

To run this examples you will need to start containers with "docker-compose" 
and after starting setup replication. See commands inside ./build.sh. 

#### Create 3 MySQL containers with primary-replica row-based replication 

```bash
./build.sh
```

#### Make changes to primary node

```bash
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root mydb -e 'create table code(code int); insert into code values (100), (200)'"
```

#### Read changes from replica node

```bash
docker exec mysql_replica_one sh -c "export MYSQL_PWD=111; mysql -u root mydb -e 'select * from code \G'"
docker exec mysql_replica_two sh -c "export MYSQL_PWD=111; mysql -u root mydb -e 'select * from code \G'"
```

## Troubleshooting

#### Check Logs

```bash
docker-compose logs
```

#### Start containers in "normal" mode

> Go through "build.sh" and run command step-by-step.

#### Check running containers

```bash
docker-compose ps
```

#### Clean data dir

```bash
rm -rf ./master/data/*
rm -rf ./slave/data/*
```

#### Run command inside primary node

```bash
docker exec mysql_master sh -c 'mysql -u root -p111 -e "SHOW MASTER STATUS \G"'
```

#### Run command inside replica node

```bash
docker exec mysql_replica_one sh -c 'mysql -u root -p111 -e "SHOW SLAVE STATUS \G"'
docker exec mysql_replica_two sh -c 'mysql -u root -p111 -e "SHOW SLAVE STATUS \G"'
```

#### Enter into primary node

```bash
docker exec -it mysql_master bash
```

#### Enter into replica node

```bash
docker exec -it mysql_replica_one bash
docker exec -it mysql_replica_two bash
```

#### References:
https://www.youtube.com/watch?v=BDZ4CNQdU_0
https://www.percona.com/blog/a-dive-into-mysql-multi-threaded-replication/
https://medium.com/booking-com-infrastructure/mysql-slave-scaling-and-more-a09d88713a20
https://dev.mysql.com/doc/refman/5.7/en/replication-options-replica.html