FROM		hauptmedia/java:oracle-java7

ENV		COREOS_CHANNEL_ID	alpha
ENV		COREOS_VERSION_ID	612.1.0
ENV		COREOS_IMAGE_URL	http://${COREOS_CHANNEL_ID}.release.core-os.net/amd64-usr/${COREOS_VERSION_ID}/coreos_production_pxe_image.cpio.gz

ENV		CASSANDRA_VERSION	2.1.3
ENV	    	CASSANDRA_HOME	/opt/cassandra
ENV         	CASSANDRA_DOWNLOAD_URL	http://www.us.apache.org/dist/cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz

# install dependencies
RUN		apt-get update -qq && \
		apt-get upgrade --yes && \
    		apt-get install -y --no-install-recommends rsync screen cpio bzip2 zsh build-essential vim curl ruby python php5-cli php5-mysql php5-curl pwgen apg mysql-client openssh-server sudo git traceroute nmap dnsutils netcat netcat6 && \
		apt-get clean autoclean && \
		apt-get autoremove --yes && \ 
		rm -rf /var/lib/{apt,dpkg,cache,log}/

# Configure sshd
RUN		mkdir /var/run/sshd && \
		sed -i 's/PermitRootLogin without-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
		sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
		sed -i 's/%sudo.*ALL=(ALL:ALL).*ALL/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers && \
		sed -i 's/session\s*required\s*pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd && \
		rm /etc/ssh/ssh_host_*

# extract fleetctl tool
WORKDIR		/tmp
RUN		curl -L --silent ${COREOS_IMAGE_URL} | zcat | cpio -iv && \
		unsquashfs usr.squashfs && \
		cp squashfs-root/bin/fleetctl /usr/local/bin && \
		rm -rf /tmp/*
	
# download and extract casandra
RUN		mkdir -p ${CASSANDRA_HOME} && \
		curl -L --silent ${CASSANDRA_DOWNLOAD_URL} | tar -xz --strip=1 -C ${CASSANDRA_HOME}

RUN		echo PATH=\$PATH:/opt/cassandra/bin >>/etc/profile

EXPOSE 22

ADD docker-entrypoint.sh /usr/local/sbin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/sbin/docker-entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D", "-E", "/proc/self/fd/2"]
