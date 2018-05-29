FROM debian:stable-slim

COPY run.sh /run.sh

RUN apt-get update --quiet --quiet \
	&& DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
		gnupg \
		openssh-server \
	&& mkdir /var/run/sshd \
	&& sed --in-place \
		-e 's!^#\?AllowTcpForwarding\s.*$!AllowTcpForwarding no!' \
		-e 's!^#\?AuthorizedKeysFile\s.*$!AuthorizedKeysFile /config/%u-authorized_keys!' \
		-e 's!^#\?PasswordAuthentication\s.*$!PasswordAuthentication no!' \
		-e 's!^#\?PermitRootLogin\s.*$!PermitRootLogin no!' \
		-e 's!^\(Subsystem\s\+sftp.*\)$!#\1!' \
		-e 's!^#\?UsePAM\s.*$!UsePAM no!' \
		-e 's!^#\?X11Forwarding\s.*$!X11Forwarding no!' \
		/etc/ssh/sshd_config \
	&& (echo "AllowUsers reprepro apt" >> /etc/ssh/sshd_config) \
	&& (echo "ForceCommand export REPREPRO_BASE_DIR=/data/debian; [ -n \"\$SSH_ORIGINAL_COMMAND\" ] && eval \"\$SSH_ORIGINAL_COMMAND\" || exec \"\$SHELL\"" >> /etc/ssh/sshd_config) \
	&& (echo "PermitRootLogin no" >> /etc/ssh/sshd_config) \
	&& (echo "Protocol 2" >> /etc/ssh/sshd_config) \
	&& DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
		reprepro \
	&& adduser --system --group \
		--shell /bin/bash \
		--disabled-password \
		--no-create-home \
		reprepro \
	&& adduser --system --group \
		--shell /bin/bash \
		--disabled-password \
		--no-create-home \
		apt \
	&& (echo "REPREPRO_BASE_DIR=/data/debian" > /etc/environment) \
	&& chmod +x /run.sh \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV REPREPRO_DEFAULT_NAME=Reprepro \
	REPREPRO_BASE_DIR=/data/debian

VOLUME ["/config", "/data"]

# sshd
EXPOSE 22

ENTRYPOINT ["/run.sh"]
