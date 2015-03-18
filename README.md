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

## Included tools

Please note that most of these tools are accessed via wrapper scripts which 
run the executable from their corresponding docker images.

That means you cannot access the local filesystem in these containers. If
you want to read or write files from the host system use the `/tmp` directory
or the current working directory which will be automatically mounted inside 
the docker containers.

### CoreOS

#### fleetctl

Management tool for CoreOS clusters

#### List machines from cluster

```bash
fleetctl list-machines
```

#### Inspect status for all running units

```bash
fleetctl list-units
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

### Cassandra

Management tools for Apache Cassandra databases

#### CQL console

```bash
cqlsh -u user -p password -k keyspace hostname port
``` 

#### See cluster status 

```bash
nodetool -h hostname status
```


