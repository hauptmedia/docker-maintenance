# docker-maintenance

A maintenance docker container for CoreOS Clusters.

It spawns an ssh server which can be used to login and execute the
provided maintenance tools.

If you provide the `/usr/bin/docker` binary and the `/var/run/docker.sock` socket file from the
host system this container will be also able to run various tools from other docker images.

If you also specify the `DOCKER_GID` environment variable the maintenance-users will be joined
to the docker group thus allowing to run docker without being root.

## maintenance-users file

Provide a `maintenance-users` users file as `/etc/maintenance-users` with the format
`user` `ssh-key` to enable the ssh login for the specified user

```
user1 ssh-rsa AAAAB3NzaC1yc2E.........
user2 ssh-rsa AAAAB3NzaC1yc2E.........
```

## Example usage (standalone)

```bash
docker run -d \
-e DOCKER_GID=$(cat /etc/group| grep docker| cut -d":" -f3) \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /usr/bin/docker:/usr/bin/docker:ro \
-v /path/to/maintenance-users:/etc/maintenance-users \
-p2022:22 \
hauptmedia/maintenance
```

## Example unit file for CoreOS

```
[Unit]
Description=CoreOS Cluster Maintenance Service
After=docker.service
Requires=docker.service

[Service]
Environment="NAME=maintenance"
TimeoutStartSec=300
ExecStartPre=/bin/sh -c "\
test -d /tmp/${NAME} && rm -rf /tmp/${NAME}; \
mkdir /tmp/${NAME}; \
/usr/bin/curl --silent https://dl.dropboxusercontent.com/u/xyz/ssh-keys.tar.gz | tar -xz -C /tmp/${NAME}; \
/usr/bin/curl --silent https://dl.dropboxusercontent.com/u/xyz/maintenance-users -o /tmp/${NAME}/maintenance-users \
"
ExecStartPre=-/usr/bin/docker kill ${NAME}
ExecStartPre=-/usr/bin/docker rm -f ${NAME}
ExecStartPre=/usr/bin/docker pull hauptmedia/maintenance
ExecStart=/usr/bin/docker run \
--name ${NAME} \
--hostname maintenance \
-e DOCKER_GID=233 \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /usr/bin/docker:/usr/bin/docker:ro \
-v /tmp/${NAME}/maintenance-users:/etc/maintenance-users \
-v /tmp/${NAME}/ssh_host_dsa_key:/etc/ssh/ssh_host_dsa_key \
-v /tmp/${NAME}/ssh_host_dsa_key.pub:/etc/ssh/ssh_host_dsa_key.pub \
-v /tmp/${NAME}/ssh_host_ecdsa_key:/etc/ssh/ssh_host_ecdsa_key \
-v /tmp/${NAME}/ssh_host_ecdsa_key.pub:/etc/ssh/ssh_host_ecdsa_key.pub \
-v /tmp/${NAME}/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key \
-v /tmp/${NAME}/ssh_host_ed25519_key.pub:/etc/ssh/ssh_host_ed25519_key.pub \
-v /tmp/${NAME}/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key \
-v /tmp/${NAME}/ssh_host_rsa_key.pub:/etc/ssh/ssh_host_rsa_key.pub \
-p 2022:22 \
hauptmedia/maintenance
ExecStop=/usr/bin/docker stop ${NAME}
Restart=always
```

## SSH server keys

The image will automatically generate new ssh server key files if you don't provide them via volume files.
You should generate the keys once and then provide them as volume files to the image.

## Included maintenance tools

Please note that most of these tools are accessed via wrapper scripts which 
run the executable from their corresponding docker images.

That means you cannot access the local filesystem in these containers. If
you want to read or write files from the host system use the `/tmp` directory
or the current working directory which will be automatically mounted inside 
the docker containers.

### CoreOS

#### fleetctl

Management tool for CoreOS clusters

```bash
# List all machines from the cluster
fleetctl list-machines

# Inspect current status of all unit files
fleetctl list-units

# Submit local unit file to repository
fleetctl submit cassandra@

# Start a single service
fleetctl start front-nginx 

# Start service cassandra on 3 machines
fleetctl start cassandra@{1..3}

# Destroy all 3 services
fleetctl destroy cassandra@{1..3}
```

### MySQL

#### MySQL Console

Management tools for MySQL databases

```bash
mysql -u user -p password -h hostname -P port database
```

#### Dump MySQL database

```bash
mysqldump -u user -p password -h hostname -P port database >mysql.dump
```

### Apache Cassandra

Management tools for Apache Cassandra databases

#### CQL console

```bash
cqlsh -u user -p password -k keyspace hostname port
``` 

#### See cluster status 

```bash
nodetool -h hostname status
```

### Apache Kafka

System tools for Apache Kafka

See https://cwiki.apache.org/confluence/display/KAFKA/System+Tools

#### kafka-consumer-offset-checker

Displays the:  Consumer Group, Topic, Partitions, Offset, logSize, Lag, Owner for the specified set of Topics and Consumer Group

```bash
# print infos about consumer group 0
kafka-consumer-offset-checker --zookeeper zk.skydns.local --group 0 --broker-info
```

#### kafka-dump-log-segments

This can print the messages directly from the log files or just verify the indexes correct for the logs

#### kafka-export-zk-offsets

A utility that retrieves the offsets of broker partitions in ZK and prints to an output file in the following format:

#### kafka-get-offset-shell

get offsets for a topic

#### kafka-import-zk-offsets

can import offsets for a topic partitions

#### kafka-jmx-tool

prints metrics via JMX

#### kafka-migration-tool

Migrates a 0.7 broker to 0.8

#### kafka-mirror-maker

Provides mirroring of one Kafka cluster to another

#### kafka-replay-log-producer

Consume from one topic and replay those messages and produce to another topic

#### kafka-simple-consumer-shell

Dumps out consumed messages to the console using the Simple Consumer

#### kafka-state-change-log-merger

A utility that merges the state change logs (possibly obtained from different brokers and over multiple days).

#### kafka-update-offsets-in-zk

A utility that updates the offset of every broker partition to the offset of earliest or latest log segment file, in ZK.

#### kafka-verify-consumer-rebalance

Make sure there is an owner for every partition. A successful rebalancing operation would select an owner for each available partition. 
This means that for each partition registered under /brokers/topics/[topic]/[broker-id], an owner exists under /consumers/[consumer_group]/owners/[topic]/[broker_id-partition_id]

### Apache Spark

Management tools for Apache Spark

#### spark-shell

Spark's shell provides a simple way to learn the API, as well as a powerful tool to analyze data interactively.

See http://spark.apache.org/docs/1.2.0/quick-start.html

```bash
spark-shell
```

#### spark-submit

The `spark-submit` script in Spark's bin directory is used to launch applications on a cluster. It can use all of Spark's supported cluster managers through a uniform interface so you don't have to configure your application specially for each one.

See http://spark.apache.org/docs/1.2.0/submitting-applications.html

```bash
spark-submit \
  --class <main-class>
  --master <master-url> \
  --deploy-mode <deploy-mode> \
  --conf <key>=<value> \
  ... # other options
  <application-jar> \
  [application-arguments]
```
