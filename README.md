# docker-maintenance

A maintenance docker container for CoreOS Clusters.

It spawns an ssh server which can be used to login and execute the
provided maintenance tools.

Provide a `maintenance-users` users file as `/etc/maintenance-users` with the format
`user` `ssh-key` to enable the ssh login for the specified user

## Example maintenance-users file

```
user1 ssh-rsa AAAAB3NzaC1yc2E.........
user2 ssh-rsa AAAAB3NzaC1yc2E.........
```

## Example usage (standalone)

```bash
docker run -d \
-v /path/to/maintenance-users:/etc/maintenance-users \
-p2022:22 \
hauptmedia/maintenance
```

## Example usage (unit file)

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

## Included tools

### MySQL

#### MySQL Console

```bash
mysql -u user -p password -h hostname -P port database
```

#### Dump MySQL database

```bash
mysqldump -u user -p password -h hostname -P port database >mysql.dump
```

### Cassandra

#### CQL console

```bash
cqlsh -u user -p password -k keyspace hostname port
``` 

#### See cluster status 

```bash
nodetool -h hostname status
```


