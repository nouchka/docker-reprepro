FROM debian:stable-slim

ENV REPREPRO_DEFAULT_NAME=Reprepro \
	REPREPRO_BASE_DIR=/data/debian \
	REPREPRO_INCOMING_DIR=/incoming

RUN apt-get update --quiet --quiet \
	&& DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
		gnupg \
		reprepro \
		lighttpd \
	&& adduser --system --group \
		--shell /bin/bash \
		--disabled-password \
		--no-create-home \
		reprepro \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/config", "/data", "/incoming"]
EXPOSE 80
ENTRYPOINT ["/run.sh"]
