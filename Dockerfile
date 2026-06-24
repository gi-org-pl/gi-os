FROM alpine:3.14

# install base dependencies + OpenSSH server
RUN apk add --no-cache \
    ca-certificates \
    curl \
    gnupg \
    iproute2 \
    iptables \
    net-tools \
    openssh-server \
    bash

# install netbird
RUN curl -fsSL https://pkgs.netbird.io/install.sh | sh
# configure sshd: allow root login, key-based only
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && echo "PrintMotd no" >> /etc/ssh/sshd_config

#welcome message
COPY gi_banner.sh /etc/profile.d/01-gi-banner.sh
RUN chmod +x /etc/profile.d/01-gi-banner.sh

ENV NB_MANAGEMENT_URL="https://vpn.gi.org.pl:443"
ENV NB_HOSTNAME=""
ENV SSH_AUTHORIZED_KEY=""

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/var/lib/netbird"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
