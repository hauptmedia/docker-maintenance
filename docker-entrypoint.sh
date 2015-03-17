#!/bin/sh
set -e 

if [ -f /etc/maintenance-users ]; then
	while read user sshkey; do
		useradd ${user} --create-home --shell /bin/bash --groups users 
		gpasswd -a ${user} sudo
		mkdir /home/${user}/.ssh
		echo ${sshkey} >/home/${user}/.ssh/authorized_keys2
		chown -R ${user}.users /home/${user}/.ssh
		chmod -R 700 /home/${user}/.ssh
	done </etc/maintenance-users
fi

exec "$@"
