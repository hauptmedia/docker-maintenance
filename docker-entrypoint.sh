#!/bin/sh
set -e 

if [ -n ${DOCKER_GID} ]; then
	groupadd -g 233 docker
fi

if [ -f /etc/maintenance-users ]; then
	while read user sshkey; do
		useradd ${user} --create-home --shell /bin/bash --groups users 
		gpasswd -a ${user} sudo
		if [ -n ${DOCKER_GID} ]; then
			gpasswd -a ${user} docker 
		fi
		mkdir /home/${user}/.ssh
		echo ${sshkey} >/home/${user}/.ssh/authorized_keys2
		chown -R ${user}.users /home/${user}/.ssh
		chmod -R 700 /home/${user}/.ssh
	done </etc/maintenance-users
fi

if [ ! -f /etc/ssh/ssh_host_rsa_key.pub ]; then
	# generate ssh keys if they are not present
	dpkg-reconfigure openssh-server
fi

exec "$@"
