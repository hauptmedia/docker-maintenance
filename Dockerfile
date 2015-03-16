FROM		hauptmedia/java:oracle-java7

# install dependencies
RUN		apt-get update -qq && \
    		apt-get install -y --no-install-recommends screen zsh build-essential vim curl ruby python php5-cli php5-mysql php5-curl pwgen apg mysql-client && \
		apt-get clean autoclean && \
		apt-get autoremove --yes && \ 
		rm -rf /var/lib/{apt,dpkg,cache,log}/
