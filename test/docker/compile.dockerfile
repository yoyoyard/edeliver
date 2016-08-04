# Docker container with capabilities to build
# elixir projects. It is used as test container
# containing the project and ededliver as local
# dependency and as "remote" build host.
FROM msaraiva/elixir-dev:1.3.1


RUN apk add --update grep autoconf alpine-sdk ncurses ncurses-dev openssl openssl-dev bash git curl erlang-tools openssh \
    && rm -rf /var/cache/apk/*

RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
RUN ssh-keygen -t rsa     -f /etc/ssh/ssh_host_rsa_key     -N ''
RUN ssh-keygen -t dsa     -f /etc/ssh/ssh_host_dsa_key     -N ''
RUN ssh-keygen -t ecdsa   -f /etc/ssh/ssh_host_ecdsa_key   -N ''

# required to use the elixir remote console
ENV TERM vt100

