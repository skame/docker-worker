#!/bin/sh

echo "${ADD_USER}:x:${ADD_UID}:${ADD_GID:-1000}::/home/${ADD_USER}:${ADD_SHELL:-/usr/bin/zsh}" >>/etc/passwd && echo "${ADD_USER}:*:16737:0:99999:7:::" >>/etc/shadow && mkdir /home/${ADD_USER} && mkdir /home/${ADD_USER}/.ssh && chown 1039 /home/${ADD_USER}/.ssh

echo "${ADD_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

