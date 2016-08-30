#!/usr/bin/env bash
set -xe
/usr/bin/docker rm -f $(/usr/bin/docker ps -q -a -f name=kube-)
