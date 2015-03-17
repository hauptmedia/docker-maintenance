FROM		hauptmedia/java:oracle-java7

# install dependencies
RUN		apt-get update -qq && \
		apt-get upgrade --yes && \
    		apt-get install -y --no-install-recommends screen zsh build-essential vim curl ruby python php5-cli php5-mysql php5-curl pwgen apg mysql-client openssh-server sudo git traceroute nmap dnsutils netcat netcat6 && \
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
	

EXPOSE 22

ADD docker-entrypoint.sh /usr/local/sbin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/sbin/docker-entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D", "-E", "/proc/self/fd/2"]
