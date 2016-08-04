#!/usr/bin/env bash
#
# Starts an ssh daemon and allows a user
# which is passed as first argument to
# authenticate with the $PUBLIC_KEY_FILE
# key.
#
SSH_USER_NAME="$1"
# must be mounted
PUBLIC_KEY_FILE="/root/.ssh/edeliver.pub"
# create user
adduser -s /bin/bash -S "$SSH_USER_NAME"
# user needs a password otherwise login is disabled
echo "${SSH_USER_NAME}:${RANDOM}" | chpasswd
# set authorized keys from mounted $PUBLIC_KEY_FILE
mkdir -p "/home/$SSH_USER_NAME/.ssh"
cat "$PUBLIC_KEY_FILE" > "/home/${SSH_USER_NAME}/.ssh/authorized_keys"
chown "$SSH_USER_NAME" -R "/home/$SSH_USER_NAME/.ssh"
chmod 0700 "/home/$SSH_USER_NAME/.ssh"
chmod 0600 "/home/$SSH_USER_NAME/.ssh/authorized_keys"
# start sshd
echo "Accepting ssh connection on $(hostname)"
/usr/sbin/sshd -D
