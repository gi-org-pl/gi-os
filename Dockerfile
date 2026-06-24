FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# install base dependencies + OpenSSH server
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    iproute2 \
    iptables \
    net-tools \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# install netbird
RUN curl -sSL https://pkgs.netbird.io/debian/public.key \
    | gpg --dearmor -o /usr/share/keyrings/netbird-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main" \
       > /etc/apt/sources.list.d/netbird.list \
    && apt-get update && apt-get install -y --no-install-recommends \
       netbird \
    && rm -rf /var/lib/apt/lists/*

# configure sshd: allow root login, key-based only
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && echo "PrintMotd yes" >> /etc/ssh/sshd_config

# custom welcome message
RUN chmod -x /etc/update-motd.d/* 2>/dev/null || true
COPY motd-banner.sh /etc/update-motd.d/01-gi-banner
COPY motd-footer.sh /etc/update-motd.d/99-footer
RUN chmod +x /etc/update-motd.d/01-gi-banner /etc/update-motd.d/99-footer \
    && truncate -s 0 /etc/motd

ENV NB_MANAGEMENT_URL="https://vpn.gi.org.pl:443"
ENV NB_HOSTNAME=""
ENV SSH_AUTHORIZED_KEY=""

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/var/lib/netbird"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
