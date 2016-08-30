#!/usr/bin/env bash
/usr/bin/docker rm -f $(/usr/bin/docker ps -q -a -f name=kube-)
