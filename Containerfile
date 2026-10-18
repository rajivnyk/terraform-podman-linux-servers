
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openssh-server \
      iproute2 \
      iputils-ping \
      procps && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash serveradmin && \
    mkdir -p /home/serveradmin/.ssh /run/sshd && \
    chmod 700 /home/serveradmin/.ssh

COPY authorized_keys /home/serveradmin/.ssh/authorized_keys

RUN chown -R serveradmin:serveradmin /home/serveradmin/.ssh && \
    chmod 600 /home/serveradmin/.ssh/authorized_keys && \
    printf '\nPubkeyAuthentication yes\nPasswordAuthentication no\nPermitRootLogin no\nAllowUsers serveradmin\n' \
      >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/bin/sh", "-c", "ssh-keygen -A && exec /usr/sbin/sshd -D -e"]
