# Container represents a staging or production host.
FROM alpine

RUN apk add --update grep openssl ncurses bash curl openssh \
    && rm -rf /var/cache/apk/*

RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
RUN ssh-keygen -t rsa     -f /etc/ssh/ssh_host_rsa_key     -N ''
RUN ssh-keygen -t dsa     -f /etc/ssh/ssh_host_dsa_key     -N ''
RUN ssh-keygen -t ecdsa   -f /etc/ssh/ssh_host_ecdsa_key   -N ''

