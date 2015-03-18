# docker-maintenance

A maintenance docker container for CoreOS Clusters.

It spawns an ssh server which can be used to login and execute the
provided maintenance tools.

If you provide the `/usr/bin/docker` binary and the `/var/run/docker.sock` from the
host system this container will be also able to run various tools from other docker images.

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
-e DOCKER_GID=$(cat /etc/group| grep docker| cut -d":" -f3) \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /usr/bin/docker:/usr/bin/docker:ro \
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

## Included tools

Please note that most of this tools are accessed via a wrapper script that
actually run the tools from the corresponding docker images.

That means you cannot access the local filesystem in these containers. If
you want to read or write files from the host system use the `/tmp` directory
which will be automatically mounted inside the docker conainers.

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


